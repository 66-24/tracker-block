function removeUtmParams(url) {
  const [base, query] = url.split("?");
  if (!query) return base;

  const params = query
    .split("&")
    .filter((param) => !param.startsWith("utm_"));

  return params.length ? `${base}?${params.join("&")}` : base;
}

async function loadTrackingUrls() {
  const response = await fetch(chrome.runtime.getURL("./tracker-urls.txt"));
  const text = await response.text();
  return text.split("\n").filter(Boolean).map((x) => x.trim());
}

async function bypassTrackingUrl(url, trackingUrls) {
  if (!(await isTrackingUrl(url, trackingUrls))) return null;

  const cleanUrl = removeUtmParams(url);
  try {
    const response = await fetch(cleanUrl, {
      method: "HEAD",
      follow: 10,
    });
    console.log("Bypassed URL:", response.url);
    return response.url; 
  } catch (err) {
    console.error("Error bypassing tracking URL:", err);
    return null;
  }
}

export async function getBypassedUrl(url) {
  const trackingUrls = await loadTrackingUrls();
  return bypassTrackingUrl(url, trackingUrls);
}