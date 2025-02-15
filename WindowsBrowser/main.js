const electron = require('electron');
const { BrowserWindow, ipcMain, session, dialog, shell } = electron;
const path = require('path');
const url = require('url');
const fs = require('fs');

// Keep a global reference of the window object to avoid garbage collection
let mainWindow;

// Create the browser window
function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1200,
        height: 800,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false,
            webviewTag: true, // Enable webview tag
            plugins: true // Enable plugins like PDF viewer
        },
        icon: path.join(__dirname, 'assets/icon.png')
    });

    // Load the index.html file
    mainWindow.loadFile('index.html');

    // Set up ad blocker
    session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
        const adBlockList = [
            '*://*.doubleclick.net/*',
            '*://*.google-analytics.com/*',
            '*://*.facebook.com/*',
            '*://creative.ak.fbcdn.net/*',
            '*://*.adbrite.com/*',
            '*://*.exponential.com/*',
            '*://*.quantserve.com/*',
            '*://*.scorecardresearch.com/*',
            '*://*.zedo.com/*',
            '*://*.googlesyndication.com/*',
            '*://*.googleadservices.com/*',
            '*://*.adnxs.com/*',
            '*://*.outbrain.com/*',
            '*://*.taboola.com/*',
            '*://*.adroll.com/*',
            '*://*.criteo.com/*'
        ];

        const shouldBlock = adBlockList.some(pattern => {
            const regexPattern = pattern.replace(/\*/g, '.*');
            return new RegExp(regexPattern).test(details.url);
        });

        callback({ cancel: shouldBlock });
    });

    // Set up download manager
    session.defaultSession.on('will-download', (event, item, webContents) => {
        // Get the file name
        const fileName = item.getFilename();
        
        // Show save dialog
        dialog.showSaveDialog({
            title: 'Save file',
            defaultPath: fileName,
            buttonLabel: 'Save'
        }).then(result => {
            if (!result.canceled) {
                item.setSavePath(result.filePath);
                
                // Handle download progress
                item.on('updated', (event, state) => {
                    if (state === 'progressing') {
                        const progress = item.getReceivedBytes() / item.getTotalBytes();
                        mainWindow.webContents.send('download-progress', {
                            filename: fileName,
                            progress: progress * 100
                        });
                    }
                });

                // Handle download completion
                item.once('done', (event, state) => {
                    if (state === 'completed') {
                        mainWindow.webContents.send('download-complete', {
                            filename: fileName,
                            success: true
                        });
                    } else {
                        mainWindow.webContents.send('download-complete', {
                            filename: fileName,
                            success: false
                        });
                    }
                });
            }
        });
    });

    // Handle window closing
    mainWindow.on('closed', () => {
        mainWindow = null;
    });

    // Handle navigation
    mainWindow.webContents.on('will-navigate', (event, url) => {
        // Allow navigation to proceed
    });

    // Enable find in page
    ipcMain.on('find-in-page', (event, searchText) => {
        mainWindow.webContents.findInPage(searchText);
    });

    // Handle external links
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
        return { action: 'deny' };
    });

    // Enable print functionality
    ipcMain.on('print-page', (event) => {
        const webview = mainWindow.webContents.fromId(event.sender.webContents.id);
        webview.print();
    });

    // Enable zoom controls
    ipcMain.on('zoom-in', () => {
        const webview = mainWindow.webContents.fromWebContents(mainWindow.webContents);
        const currentZoom = webview.getZoomFactor();
        webview.setZoomFactor(currentZoom + 0.1);
    });

    ipcMain.on('zoom-out', () => {
        const webview = mainWindow.webContents.fromWebContents(mainWindow.webContents);
        const currentZoom = webview.getZoomFactor();
        webview.setZoomFactor(currentZoom - 0.1);
    });

    ipcMain.on('zoom-reset', () => {
        const webview = mainWindow.webContents.fromWebContents(mainWindow.webContents);
        webview.setZoomFactor(1.0);
    });
}

// Initialize app
electron.app.whenReady().then(createWindow);

// Quit when all windows are closed
electron.app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        electron.app.quit();
    }
});

// Recreate window when dock icon is clicked (macOS)
electron.app.on('activate', () => {
    if (mainWindow === null) {
        createWindow();
    }
});

// Handle search queries
ipcMain.on('search', (event, query) => {
    const searchUrl = `https://www.google.com/search?q=${encodeURIComponent(query)}`;
    const webview = mainWindow.webContents.fromWebContents(mainWindow.webContents);
    webview.loadURL(searchUrl);
});

// Handle new window creation
electron.app.on('web-contents-created', (event, contents) => {
    contents.on('new-window', (event, navigationUrl) => {
        event.preventDefault();
        const webview = mainWindow.webContents.fromWebContents(mainWindow.webContents);
        webview.loadURL(navigationUrl);
    });
});

// Enable spellchecker
electron.app.on('ready', () => {
    session.defaultSession.setSpellCheckerLanguages(['en-US']);
});

// Handle bookmark management
let bookmarks = [];

ipcMain.on('add-bookmark', (event, bookmark) => {
    if (!bookmarks.some(b => b.url === bookmark.url)) {
        bookmarks.push(bookmark);
        event.reply('bookmarks-updated', bookmarks);
    }
});

ipcMain.on('get-bookmarks', (event) => {
    event.reply('bookmarks-updated', bookmarks);
});

// Enable history tracking
let history = [];

ipcMain.on('add-to-history', (event, historyItem) => {
    history.push({
        url: historyItem.url,
        title: historyItem.title,
        timestamp: Date.now()
    });
});

ipcMain.on('get-history', (event) => {
    event.reply('history-list', history);
});
