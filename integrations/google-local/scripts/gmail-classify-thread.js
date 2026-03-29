const { loadAuthorizedClient, google } = require('./_shared');
const { findBestBody, headerMap, compactText } = require('./_gmail-utils');
const { classifyThread } = require('./_gmail-thread-heuristics');

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
    return {
      id: msg.id,
      from: headers.from || '',
      to: headers.to || '',
      subject: headers.subject || '',
      date: headers.date || '',
      snippet: msg.snippet || '',
      bodyPreview: compactText(findBestBody(msg.payload), 1200)
    };
  });

  const participants = [...new Set(messages.flatMap(m => [m.from, m.to]).filter(Boolean))];
  const latestMessage = messages[messages.length - 1] || null;
  const summary = {
    threadId: thread.id,
    subject: messages[0]?.subject || '',
    participants,
    latestMessage,
    messageCount: messages.length,
    timeline: messages
  };

  const classification = classifyThread(summary);
  console.log(JSON.stringify({ ...summary, classification }, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify(err.response?.data || { error: err.message || String(err) }, null, 2));
  process.exit(1);
});
