const { loadAuthorizedClient, google } = require('./_shared');

const scopes = [
  'https://www.googleapis.com/auth/contacts.readonly',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
];

async function main() {
  const auth = loadAuthorizedClient('contacts-readonly', scopes);
  const people = google.people({ version: 'v1', auth });
  const pageSize = Number(process.argv[2] || 10);
  const res = await people.people.connections.list({
    resourceName: 'people/me',
    pageSize,
    personFields: 'names,emailAddresses,phoneNumbers'
  });
  console.log(JSON.stringify(res.data, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify(err.response?.data || { error: err.message || String(err) }, null, 2));
  process.exit(1);
});
