const electron = require('electron');
const { app, BrowserWindow, ipcMain, session, dialog, shell } = electron;
const path = require('path');
const url = require('url');
const fs = require('fs');

// Keep a global reference of window objects
let windows = new Set();
let mainWindow;

// Create a new browser window
function createWindow(isMainWindow = false) {
    try {
        const win = new BrowserWindow({
            width: 1200,
            height: 800,
            webPreferences: {
                nodeIntegration: true,
                contextIsolation: false,
                webviewTag: true,
                plugins: true,
                sandbox: false
            },
            icon: path.join(__dirname, 'assets/icon.png')
        });

        if (isMainWindow) {
            mainWindow = win;
            win.loadFile('index.html').catch(err => {
                console.error('Failed to load index.html:', err);
            });
        } else {
            win.loadFile('index.html').catch(err => {
                console.error('Failed to load index.html:', err);
            });
        }

        windows.add(win);

        // Set up ad blocker
        session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
            try {
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
            } catch (err) {
                console.error('Ad blocker error:', err);
                callback({ cancel: false });
            }
        });

        // Handle window closing
        win.on('closed', () => {
            windows.delete(win);
            if (win === mainWindow) {
                mainWindow = null;
            }
        });

        return win;

    } catch (err) {
        console.error('Window creation error:', err);
    }
}

// Initialize app
app.whenReady().then(() => {
    createWindow(true);
    
    const { Menu } = electron;
    const template = [
        {
            label: 'File',
            submenu: [
                {
                    label: 'New Window',
                    accelerator: 'CmdOrCtrl+N',
                    click: () => createWindow()
                }
            ]
        }
    ];
    Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}).catch(err => {
    console.error('App initialization error:', err);
});

// Quit when all windows are closed
app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

// Recreate window when dock icon is clicked (macOS)
app.on('activate', () => {
    if (windows.size === 0) {
        createWindow(true);
    }
});

// Handle bookmarks
let bookmarks = [];

ipcMain.on('add-bookmark', (event, bookmark) => {
    try {
        if (bookmark && bookmark.url && !bookmarks.some(b => b.url === bookmark.url)) {
            bookmarks.push(bookmark);
            event.reply('bookmarks-updated', bookmarks);
        }
    } catch (err) {
        console.error('Bookmark add error:', err);
    }
});

ipcMain.on('get-bookmarks', (event) => {
    try {
        event.reply('bookmarks-updated', bookmarks);
    } catch (err) {
        console.error('Get bookmarks error:', err);
    }
});

// Handle AI summary
ipcMain.on('generate-summary', async (event, pageContent) => {
    try {
        // Simulate AI summary generation
        const summary = `This is a simulated AI summary of the page content. 
                        In a real implementation, you would integrate with an AI service.
                        Page length: ${pageContent.length} characters`;
        event.reply('summary-result', summary);
    } catch (err) {
        console.error('Summary generation error:', err);
        event.reply('summary-result', 'Failed to generate summary');
    }
});

// Handle history
let history = [];

ipcMain.on('update-history', (event, historyItem) => {
    try {
        if (historyItem && historyItem.url) {
            history.push({
                ...historyItem,
                timestamp: Date.now()
            });
        }
    } catch (err) {
        console.error('History update error:', err);
    }
});

// Handle downloads
app.on('web-contents-created', (event, contents) => {
    contents.session.on('will-download', (event, item, webContents) => {
        try {
            const fileName = item.getFilename();
            
            dialog.showSaveDialog({
                title: 'Save file',
                defaultPath: fileName,
                buttonLabel: 'Save'
            }).then(result => {
                if (!result.canceled) {
                    item.setSavePath(result.filePath);
                    
                    item.on('updated', (event, state) => {
                        if (state === 'progressing') {
                            const progress = item.getReceivedBytes() / item.getTotalBytes();
                            webContents.send('download-progress', {
                                filename: fileName,
                                progress: progress * 100
                            });
                        }
                    });

                    item.once('done', (event, state) => {
                        webContents.send('download-complete', {
                            filename: fileName,
                            success: state === 'completed'
                        });
                    });
                }
            });
        } catch (err) {
            console.error('Download error:', err);
        }
    });

    // Handle new window/tab creation
    contents.setWindowOpenHandler(({ url }) => {
        try {
            shell.openExternal(url);
            return { action: 'deny' };
        } catch (err) {
            console.error('External link error:', err);
            return { action: 'deny' };
        }
    });
});
