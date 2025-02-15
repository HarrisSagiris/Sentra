const electron = require('electron');
const { BrowserWindow, ipcMain, session, dialog, shell } = electron;
const path = require('path');
const url = require('url');
const fs = require('fs');

// Keep a global reference of the window object to avoid garbage collection
let mainWindow;

// Create the browser window
function createWindow() {
    try {
        mainWindow = new BrowserWindow({
            width: 1200,
            height: 800,
            webPreferences: {
                nodeIntegration: true,
                contextIsolation: false,
                webviewTag: true,
                plugins: true,
                sandbox: false // Disable sandbox for full functionality
            },
            icon: path.join(__dirname, 'assets/icon.png')
        });

        // Load the index.html file
        mainWindow.loadFile('index.html').catch(err => {
            console.error('Failed to load index.html:', err);
        });

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

        // Set up download manager
        session.defaultSession.on('will-download', (event, item, webContents) => {
            try {
                const fileName = item.getFilename();
                
                dialog.showSaveDialog({
                    title: 'Save file',
                    defaultPath: fileName,
                    buttonLabel: 'Save'
                }).then(result => {
                    if (!result.canceled && mainWindow) {
                        item.setSavePath(result.filePath);
                        
                        item.on('updated', (event, state) => {
                            if (state === 'progressing' && mainWindow) {
                                const progress = item.getReceivedBytes() / item.getTotalBytes();
                                mainWindow.webContents.send('download-progress', {
                                    filename: fileName,
                                    progress: progress * 100
                                });
                            }
                        });

                        item.once('done', (event, state) => {
                            if (mainWindow) {
                                mainWindow.webContents.send('download-complete', {
                                    filename: fileName,
                                    success: state === 'completed'
                                });
                            }
                        });
                    }
                }).catch(err => {
                    console.error('Save dialog error:', err);
                });
            } catch (err) {
                console.error('Download error:', err);
            }
        });

        // Handle window closing
        mainWindow.on('closed', () => {
            mainWindow = null;
        });

        // Handle navigation
        mainWindow.webContents.on('will-navigate', (event, url) => {
            // Allow navigation to proceed
            try {
                // Add any navigation validation here
            } catch (err) {
                console.error('Navigation error:', err);
            }
        });

        // Enable find in page
        ipcMain.on('find-in-page', (event, searchText) => {
            try {
                if (mainWindow && searchText) {
                    mainWindow.webContents.findInPage(searchText);
                }
            } catch (err) {
                console.error('Find in page error:', err);
            }
        });

        // Handle external links
        mainWindow.webContents.setWindowOpenHandler(({ url }) => {
            try {
                if (url) {
                    shell.openExternal(url);
                }
                return { action: 'deny' };
            } catch (err) {
                console.error('External link error:', err);
                return { action: 'deny' };
            }
        });

        // Enable print functionality
        ipcMain.on('print-page', (event) => {
            try {
                if (mainWindow && event.sender) {
                    const webview = mainWindow.webContents.fromId(event.sender.webContents.id);
                    if (webview) {
                        webview.print();
                    }
                }
            } catch (err) {
                console.error('Print error:', err);
            }
        });

        // Enable zoom controls
        ipcMain.on('zoom-in', () => {
            try {
                if (mainWindow) {
                    const webview = mainWindow.webContents;
                    const currentZoom = webview.getZoomFactor();
                    webview.setZoomFactor(Math.min(currentZoom + 0.1, 3.0));
                }
            } catch (err) {
                console.error('Zoom in error:', err);
            }
        });

        ipcMain.on('zoom-out', () => {
            try {
                if (mainWindow) {
                    const webview = mainWindow.webContents;
                    const currentZoom = webview.getZoomFactor();
                    webview.setZoomFactor(Math.max(currentZoom - 0.1, 0.3));
                }
            } catch (err) {
                console.error('Zoom out error:', err);
            }
        });

        ipcMain.on('zoom-reset', () => {
            try {
                if (mainWindow) {
                    mainWindow.webContents.setZoomFactor(1.0);
                }
            } catch (err) {
                console.error('Zoom reset error:', err);
            }
        });

    } catch (err) {
        console.error('Window creation error:', err);
    }
}

// Initialize app
electron.app.whenReady().then(createWindow).catch(err => {
    console.error('App initialization error:', err);
});

// Quit when all windows are closed
electron.app.on('window-all-closed', () => {
    try {
        if (process.platform !== 'darwin') {
            electron.app.quit();
        }
    } catch (err) {
        console.error('App quit error:', err);
    }
});

// Recreate window when dock icon is clicked (macOS)
electron.app.on('activate', () => {
    try {
        if (mainWindow === null) {
            createWindow();
        }
    } catch (err) {
        console.error('Window recreation error:', err);
    }
});

// Handle search queries
ipcMain.on('search', (event, query) => {
    try {
        if (mainWindow && query) {
            const searchUrl = `https://www.google.com/search?q=${encodeURIComponent(query)}`;
            mainWindow.webContents.loadURL(searchUrl);
        }
    } catch (err) {
        console.error('Search error:', err);
    }
});

// Handle new window creation
electron.app.on('web-contents-created', (event, contents) => {
    contents.on('new-window', (event, navigationUrl) => {
        try {
            event.preventDefault();
            if (mainWindow && navigationUrl) {
                mainWindow.webContents.loadURL(navigationUrl);
            }
        } catch (err) {
            console.error('New window error:', err);
        }
    });
});

// Enable spellchecker
electron.app.on('ready', () => {
    try {
        session.defaultSession.setSpellCheckerLanguages(['en-US']);
    } catch (err) {
        console.error('Spellchecker error:', err);
    }
});

// Handle bookmark management
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

// Enable history tracking
let history = [];

ipcMain.on('add-to-history', (event, historyItem) => {
    try {
        if (historyItem && historyItem.url) {
            history.push({
                url: historyItem.url,
                title: historyItem.title || '',
                timestamp: Date.now()
            });
        }
    } catch (err) {
        console.error('History add error:', err);
    }
});

ipcMain.on('get-history', (event) => {
    try {
        event.reply('history-list', history);
    } catch (err) {
        console.error('Get history error:', err);
    }
});
