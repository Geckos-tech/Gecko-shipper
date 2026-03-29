const { loadAuthorizedClient, google } = require('./_shared');
const { findBestBody, headerMap } = require('./_gmail-utils');

const scopes = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
];

async function main() {
  const mode = process.argv[2];
  const id = process.argv[3];
  if (!mode || !id || !['message', 'thread'].includes(mode)) {
    throw new Error('Usage: node scripts/gmail-extract.js <message|thread> <id>');
  }

  const auth = loadAuthorizedClient('gmail-readonly', scopes);
  const gmail = google.gmail({ version: 'v1', auth });

  if (mode === 'message') {
    const res = await gmail.users.messages.get({ userId: 'me', id, format: 'full' });
    const msg = res.data;
    const headers = headerMap(msg.payload?.headers || []);
    const bodyText = findBestBody(msg.payload);
    console.log(JSON.stringify({
      id: msg.id,
      threadId: msg.threadId,
      subject: headers.subject || '',
      from: headers.from || '',
      to: headers.to || '',
      date: headers.date || '',
      snippet: msg.snippet || '',
      bodyText
    }, null, 2));
    return;
  }

  const res = await gmail.users.threads.get({ userId: 'me', id, format: 'full' });
  const thread = res.data;
  const messages = (thread.messages || []).map(msg => {
    const headers = headerMap(msg.payload?.headers || []);
    return {
      id: msg.id,
      subject: headers.subject || '',
      from: headers.from || '',
      to: headers.to || '',
      date: headers.date || '',
      snippet: msg.snippet || '',
      bodyText: findBestBody(msg.payload)
    };
  });
  console.log(JSON.stringify({ id: thread.id, messages }, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify(err.response?.data || { error: err.message || String(err) }, null, 2));
  process.exit(1);
});
