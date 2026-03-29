const { loadAuthorizedClient, google } = require('./_shared');

const scopes = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
];

async function main() {
  const auth = loadAuthorizedClient('gmail-readonly', scopes);
  const gmail = google.gmail({ version: 'v1', auth });
  const q = process.argv.slice(2).join(' ').trim();
  if (!q) throw new Error('Provide a Gmail search query.');
  const res = await gmail.users.messages.list({ userId: 'me', q, maxResults: 10 });
  console.log(JSON.stringify(res.data, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify(err.response?.data || { error: err.message || String(err) }, null, 2));
  process.exit(1);
});
