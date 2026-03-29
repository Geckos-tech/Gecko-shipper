const { loadAuthorizedClient, google } = require('./_shared');
const { findBestBody, headerMap, compactText } = require('./_gmail-utils');

const scopes = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
];

async function main() {
  const id = process.argv[2];
  if (!id) throw new Error('Provide a Gmail thread id.');

  const auth = loadAuthorizedClient('gmail-readonly', scopes);
  const gmail = google.gmail({ version: 'v1', auth });
  const res = await gmail.users.threads.get({ userId: 'me', id, format: 'full' });
  const thread = res.data;

  const messages = (thread.messages || []).map(msg => {
    const headers = headerMap(msg.payload?.headers || []);
    const bodyText = compactText(findBestBody(msg.payload));
    return {
      id: msg.id,
      from: headers.from || '',
      to: headers.to || '',
      subject: headers.subject || '',
      date: headers.date || '',
      snippet: msg.snippet || '',
      bodyPreview: bodyText
    };
  });

  const participants = [...new Set(messages.flatMap(m => [m.from, m.to]).filter(Boolean))];
  const latest = messages[messages.length - 1] || null;

  console.log(JSON.stringify({
    threadId: thread.id,
    subject: messages[0]?.subject || '',
    messageCount: messages.length,
    participants,
    latestMessage: latest,
    timeline: messages
  }, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify(err.response?.data || { error: err.message || String(err) }, null, 2));
  process.exit(1);
});
