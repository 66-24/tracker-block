chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("background.js received:", message);

  if (message.open) {
    chrome.tabs.create({ url: message.open });
  }
});
