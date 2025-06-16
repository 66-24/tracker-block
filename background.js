chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.open) {
    chrome.tabs.create({ url: message.open });
  }
});
