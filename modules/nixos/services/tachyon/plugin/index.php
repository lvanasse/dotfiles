<?php

class TachyonLocalPlugin extends \Tachyon\Plugins\AbstractPlugin
{
	const
		NAME = 'TachyonLocal',
		AUTHOR = 'Local deployment',
		URL = 'https://github.com/kimusan/Tachyon',
		VERSION = '1.1',
		RELEASE = '2026-10-13',
		REQUIRED = '4.4.2',
		CATEGORY = 'General',
		LICENSE = 'MIT',
		DESCRIPTION = 'Local usability additions for this deployment';

	public function Init() : void
	{
		$this->addJs('tachyon-local.js');
	}
}
