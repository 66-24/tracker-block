import { bypassTrackingUrl } from "./tracking-blocker.js";

console.log("[tracker-block] content script loaded");

fetch(chrome.runtime.getURL("tracking_urls.txt"))
  .then((res) => res.text())
  .then((text) => {
    const trackingUrls = text.split("\n").filter(Boolean).map((x) => x.trim());

    const links = document.querySelectorAll("a");
    links.forEach((link) => {
      const href = link.href;
      if (trackingUrls.some((prefix) => href.startsWith(prefix))) {
        link.style.backgroundColor = "yellow";
        link.addEventListener("click", async (e) => {
          e.preventDefault();
          const finalUrl = await bypassTrackingUrl(href);
          if (finalUrl) {
            chrome.runtime.sendMessage({ open: finalUrl }); // 👈 send to background
          }
        });
      }
    });
  });
