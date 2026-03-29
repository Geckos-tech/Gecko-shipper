const { loadAuthorizedClient, google } = require('./_shared');

const scopes = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
];

async function main() {
  const id = process.argv[2];
  if (!id) throw new Error('Provide a Gmail message id.');
  const auth = loadAuthorizedClient('gmail-readonly', scopes);
  const gmail = google.gmail({ version: 'v1', auth });
  const res = await gmail.users.messages.get({ userId: 'me', id, format: 'full' });
  console.log(JSON.stringify(res.data, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify(err.response?.data || { error: err.message || String(err) }, null, 2));
  process.exit(1);
});
