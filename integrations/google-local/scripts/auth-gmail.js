const { runLocalAuthFlow } = require('./_shared');

const scopes = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
];

runLocalAuthFlow('gmail-readonly', scopes).catch(err => {
  console.error(err);
  process.exit(1);
});
