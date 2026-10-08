const path = require('node:path');

function pythonExecutable(root, platform = process.platform, override = process.env.PHOTO_HUB_PYTHON) {
  return override || path.join(root, platform === 'win32' ? '.venv/Scripts/python.exe' : '.venv/bin/python');
}

function menuTemplate(platform, showLibrary) {
  const mac = platform === 'darwin';
  return [
    ...(mac ? [{ label: 'Photo Hub', submenu: [
      { role: 'about' }, { type: 'separator' }, { role: 'services' },
      { type: 'separator' }, { role: 'hide' }, { role: 'hideOthers' }, { role: 'unhide' },
      { type: 'separator' }, { role: 'quit', label: 'Photo Hubを終了' },
    ] }] : []),
    { label: 'ファイル', submenu: [
      { label: '保存先を確認', click: showLibrary }, { type: 'separator' },
      mac ? { role: 'close', label: 'ウィンドウを閉じる' } : { role: 'quit', label: '終了' },
    ] },
    { label: '編集', submenu: [{ role: 'undo' }, { role: 'redo' }, { type: 'separator' }, { role: 'cut' }, { role: 'copy' }, { role: 'paste' }, { role: 'selectAll' }] },
    { label: '表示', submenu: [{ role: 'reload' }, { role: 'resetZoom' }, { role: 'zoomIn' }, { role: 'zoomOut' }, { role: 'togglefullscreen' }] },
    ...(mac ? [{ role: 'windowMenu', label: 'ウィンドウ' }] : []),
  ];
}

module.exports = { pythonExecutable, menuTemplate };
