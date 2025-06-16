import { bypassTrackingUrl } from "./tracking-blocker.js";

console.log("[tracker-block] content script loaded");

const trackingFile = chrome.runtime.getURL("tracker-urls.txt");

fetch(trackingFile)
  .then((res) => {
    if (!res.ok) throw new Error(`Failed to load: ${trackingFile}`);
    return res.text();
  })
  .then((text) => {
    const trackingUrls = text
      .split("\n")
      .map((x) => x.trim())
      .filter(Boolean);

    const links = document.querySelectorAll("a");
    links.forEach((link) => {
      const href = link.href;
      if (trackingUrls.some((prefix) => href.startsWith(prefix))) {
        link.style.backgroundColor = "yellow";

        link.addEventListener("click", async (e) => {
          e.preventDefault();

          try {
            const finalUrl = await getBypassedUrl(href);
            if (finalUrl) {
              chrome.runtime.sendMessage({ open: finalUrl }, (response) => {
                if (chrome.runtime.lastError) {
                  console.error("Message failed:", chrome.runtime.lastError.message);
                } else {
                  console.log("Message sent:", finalUrl);
                }
              });
            }
          } catch (err) {
            console.error("Failed to bypass:", err);
          }
        });
      }
    });
  })
  .catch((err) => {
    console.error("[tracker-block] Could not load tracking list:", err);
  });
