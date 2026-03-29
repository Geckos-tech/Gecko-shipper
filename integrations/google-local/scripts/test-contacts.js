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
  const res = await people.people.connections.list({
    resourceName: 'people/me',
    pageSize: 10,
    personFields: 'names,emailAddresses,phoneNumbers'
  });
  console.log(JSON.stringify(res.data, null, 2));
}

main().catch(err => {
  console.error(err.response?.data || err.message || err);
  process.exit(1);
});
