function decodeBase64Url(input) {
  if (!input) return '';
  const normalized = input.replace(/-/g, '+').replace(/_/g, '/');
  return Buffer.from(normalized, 'base64').toString('utf8');
}

function decodeHtmlEntities(text) {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&reg;/g, '®')
    .replace(/&copy;/g, '©');
}

function stripHtml(html) {
  return decodeHtmlEntities(
    html
      .replace(/<style[\s\S]*?<\/style>/gi, ' ')
      .replace(/<script[\s\S]*?<\/script>/gi, ' ')
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/p>/gi, '\n\n')
      .replace(/<\/div>/gi, '\n')
      .replace(/<li>/gi, '\n- ')
      .replace(/<[^>]+>/g, ' ')
  )
    .replace(/\r/g, '')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n[ \t]+/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function cleanText(text) {
  if (!text) return '';
  return decodeHtmlEntities(text)
    .replace(/\r/g, '')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n[ \t]+/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function looksLikeNoise(line) {
  const trimmed = line.trim();
  if (!trimmed) return true;
  if (/^(view order details|go to faq'?s|go to click-n-ship|usps\.com|privacy policy|support|faqs)$/i.test(trimmed)) return true;
  if (/^this is an automated email; please do not reply/i.test(trimmed)) return true;
  if (/^copyright ©/i.test(trimmed)) return true;
  if (/^download usps mobile/i.test(trimmed)) return true;
  if (/^[|•·]+$/.test(trimmed)) return true;
  return false;
}

function normalizeBodyText(text) {
  const lines = cleanText(text)
    .split('\n')
    .map(l => l.trim())
    .filter(l => !looksLikeNoise(l));

  const collapsed = [];
  for (const line of lines) {
    if (!line) continue;
    if (collapsed[collapsed.length - 1] === line) continue;
    collapsed.push(line);
  }

  return collapsed.join('\n');
}

function findBestBody(payload) {
  if (!payload) return '';
  const queue = [payload];
  let html = '';
  let text = '';

  while (queue.length) {
    const part = queue.shift();
    if (part.parts?.length) queue.push(...part.parts);
    const mimeType = part.mimeType || '';
    const data = part.body?.data;
    if (!data) continue;
    const decoded = decodeBase64Url(data);
    if (!decoded) continue;
    if (mimeType === 'text/plain' && !text) text = decoded;
    if (mimeType === 'text/html' && !html) html = decoded;
  }

  return normalizeBodyText(text || stripHtml(html) || '');
}

function headerMap(headers = []) {
  const out = {};
  for (const h of headers) {
    if (!h?.name) continue;
    out[h.name.toLowerCase()] = h.value || '';
  }
  return out;
}

function compactText(text, maxLen = 600) {
  const cleaned = normalizeBodyText(text);
  if (cleaned.length <= maxLen) return cleaned;
  return cleaned.slice(0, maxLen).trim() + '…';
}

module.exports = {
  decodeBase64Url,
  stripHtml,
  cleanText,
  normalizeBodyText,
  findBestBody,
  headerMap,
  compactText,
};
