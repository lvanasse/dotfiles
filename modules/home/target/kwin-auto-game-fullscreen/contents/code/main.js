const gameWindowClass = /^steam_app_.*/i;
const excludedGameCaption = /heroes of the storm/i;
const geometryTolerance = 1;

function approximatelyEqual(left, right) {
  return Math.abs(left - right) <= geometryTolerance;
}

function coversFullOutput(window) {
  const windowGeometry = window.frameGeometry;
  const outputGeometry = workspace.clientArea(KWin.FullScreenArea, window);

  return (
    approximatelyEqual(windowGeometry.x, outputGeometry.x) &&
    approximatelyEqual(windowGeometry.y, outputGeometry.y) &&
    approximatelyEqual(windowGeometry.width, outputGeometry.width) &&
    approximatelyEqual(windowGeometry.height, outputGeometry.height)
  );
}

function isGameWindow(window) {
  return (
    !excludedGameCaption.test(window.caption) &&
    gameWindowClass.test(window.resourceClass) ||
    (!excludedGameCaption.test(window.caption) &&
      gameWindowClass.test(window.resourceName))
  );
}

function correctFullscreenState(window) {
  if (
    window.normalWindow &&
    window.fullScreenable &&
    !window.fullScreen &&
    isGameWindow(window) &&
    coversFullOutput(window)
  ) {
    window.fullScreen = true;
  }
}

function watchWindow(window) {
  window.frameGeometryChanged.connect(() => correctFullscreenState(window));
  window.windowClassChanged.connect(() => correctFullscreenState(window));
  correctFullscreenState(window);
}

for (const window of workspace.windowList()) {
  watchWindow(window);
}

workspace.windowAdded.connect(watchWindow);
