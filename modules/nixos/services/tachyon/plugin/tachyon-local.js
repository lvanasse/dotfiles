(rl => {
	if (!rl) return;

	const addReadToggle = detail => {
		if (detail.viewModelTemplateID !== 'MailMessageList') return;
		const dom = detail.viewModelDom;
		const vm = detail;
		const toolbar = dom?.querySelector('.btn-toolbar');
		if (!toolbar) return;
		const refreshIcon = toolbar.querySelector('a[data-bind="click: reload"] .icon-spinner.not-animated');
		if (refreshIcon) refreshIcon.className = 'icon-refresh-cw';
		if (toolbar.querySelector('.tachyon-local-read-toggle')) return;
		const button = document.createElement('a');
		button.className = 'btn tachyon-local-read-toggle';
		button.href = '#';
		button.setAttribute('title', 'Mark selected messages read/unread');
		button.setAttribute('aria-label', 'Mark selected messages read/unread');
		button.innerHTML = '<i class="icon-mail-open"></i>';
		button.addEventListener('click', event => {
			event.preventDefault();
			const selected = vm.messageList?.listCheckedOrSelected?.() || [];
			if (selected.length) {
				vm.seenMessagesFast?.(!selected.every(message => !message.isUnseen()));
			}
		});
		toolbar.insertBefore(button, toolbar.querySelector('.onCheckedShow'));
	};

	const addCalendarFields = detail => {
		if (detail.viewModelTemplateID !== 'PopupsCalendar') return;
		const dom = detail.viewModelDom;
		const form = dom?.querySelector('.b-calendar-editor-form');
		if (!form || form.querySelector('.tachyon-local-reminder')) return;
		const group = document.createElement('div');
		group.className = 'control-group tachyon-local-reminder';
		group.innerHTML = '<label>Reminder</label><select class="span5"><option value="0">None</option><option value="5">5 minutes before</option><option value="10">10 minutes before</option><option value="15">15 minutes before</option><option value="30">30 minutes before</option><option value="60">1 hour before</option><option value="1440">1 day before</option></select>';
		const select = group.querySelector('select');
		select.addEventListener('change', () => { window.__tachyonReminder = Number(select.value) || 0; });
		const description = form.querySelector('textarea');
		(description?.closest('.control-group') || form.querySelector('.buttons'))?.before(group);
	};

	const originalFetchJSON = rl.fetchJSON;
	rl.fetchJSON = (url, options, params) => {
		if (params?.Action === 'CalendarEventSave') {
			params.Reminder = Number(window.__tachyonReminder) || 0;
		}
		return originalFetchJSON(url, options, params);
	};

	addEventListener('rl-view-model', event => {
		addReadToggle(event.detail);
		addCalendarFields(event.detail);
	});
})(window.rl);
