const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('photoHub', {
  chooseDirectory: () => ipcRenderer.invoke('choose-storage-directory'),
});
