const fs = require('fs');
const path = require('path');
const { loadAuthorizedClient, google } = require('./_shared');
const { headerMap } = require('./_gmail-utils');

const scopes = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
];

function sanitize(input) {
  return String(input || '')
    .replace(/[\\/:*?"<>|]+/g, '-')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function datePrefix(dateHeader) {
  const d = new Date(dateHeader);
  if (Number.isNaN(d.getTime())) return 'unknown-date';
  return d.toISOString().slice(0, 10);
}

async function main() {
  const messageId = process.argv[2];
  const outDir = process.argv[3];
  const descriptor = process.argv[4] || 'attachment';
  if (!messageId || !outDir) throw new Error('Usage: node scripts/gmail-download-attachments.js <messageId> <outDir> [descriptor]');

  fs.mkdirSync(outDir, { recursive: true });

  const auth = loadAuthorizedClient('gmail-readonly', scopes);
  const gmail = google.gmail({ version: 'v1', auth });
  const res = await gmail.users.messages.get({ userId: 'me', id: messageId, format: 'full' });
  const msg = res.data;
  const headers = headerMap(msg.payload?.headers || []);
  const prefix = datePrefix(headers.date);

  const saved = [];
  const skipped = [];
  const parts = msg.payload?.parts || [];
  let photoIndex = 1;

  for (const part of parts) {
    const mime = part.mimeType || '';
    const filename = part.filename || '';
    const attachmentId = part.body?.attachmentId;
    if (!attachmentId || !filename) continue;

    if (!mime.startsWith('image/')) {
      skipped.push({ filename, mimeType: mime, reason: 'not-photo' });
      continue;
    }

    const ext = path.extname(filename) || '.jpg';
    const safeName = `${prefix}_${sanitize(descriptor)}-${photoIndex}${ext}`;
    const fullPath = path.join(outDir, safeName);
    const attachment = await gmail.users.messages.attachments.get({ userId: 'me', messageId, id: attachmentId });
    const data = attachment.data.data.replace(/-/g, '+').replace(/_/g, '/');
    fs.writeFileSync(fullPath, Buffer.from(data, 'base64'));
    saved.push({ filename: safeName, path: fullPath, sourceFilename: filename, mimeType: mime });
    photoIndex += 1;
  }

  console.log(JSON.stringify({ saved, skipped }, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify(err.response?.data || { error: err.message || String(err) }, null, 2));
  process.exit(1);
});
