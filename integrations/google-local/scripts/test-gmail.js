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
  const res = await gmail.users.messages.list({ userId: 'me', maxResults: 5 });
  console.log(JSON.stringify(res.data, null, 2));
}

main().catch(err => {
  console.error(err.response?.data || err.message || err);
  process.exit(1);
});
