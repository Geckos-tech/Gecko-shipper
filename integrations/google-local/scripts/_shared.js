const fs = require('fs');
const path = require('path');
const http = require('http');
const {google} = require('googleapis');

const ROOT = path.resolve(__dirname, '..');
const AUTH_ROOT = path.join(ROOT, 'auth');
const CLIENT_SECRET_PATH = path.join(process.env.USERPROFILE || process.env.HOME, '.config', 'gws', 'client_secret.json');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function readClientSecrets() {
  const raw = JSON.parse(fs.readFileSync(CLIENT_SECRET_PATH, 'utf8'));
  return raw.installed || raw.web;
}

function getProfilePaths(profile) {
  const profileDir = path.join(AUTH_ROOT, profile);
  ensureDir(profileDir);
  return {
    profileDir,
    tokenPath: path.join(profileDir, 'token.json')
  };
}

function createOAuthClient(scopes) {
  const creds = readClientSecrets();
  const redirectUri = (creds.redirect_uris || []).find(u => u.startsWith('http://localhost')) || 'http://localhost:53105';
  const oauth2Client = new google.auth.OAuth2(creds.client_id, creds.client_secret, redirectUri);
  return oauth2Client;
}

async function runLocalAuthFlow(profile, scopes) {
  const oauth2Client = createOAuthClient(scopes);
  const { tokenPath } = getProfilePaths(profile);
  const redirectUrl = new URL(oauth2Client.redirectUri);
  const port = Number(redirectUrl.port || 80);
  const hostname = redirectUrl.hostname;

  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: scopes,
    prompt: 'consent'
  });

  console.log('Open this URL in your browser to authenticate:');
  console.log(authUrl);

  const code = await new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      try {
        const reqUrl = new URL(req.url, `${redirectUrl.protocol}//${req.headers.host}`);
        const incomingCode = reqUrl.searchParams.get('code');
        if (incomingCode) {
          res.writeHead(200, {'Content-Type': 'text/plain'});
          res.end('Authentication complete. You can close this window.');
          server.close(() => resolve(incomingCode));
        } else {
          res.writeHead(400, {'Content-Type': 'text/plain'});
          res.end('Missing code parameter.');
        }
      } catch (err) {
        reject(err);
      }
    });
    server.listen(port, hostname, () => {});
    server.on('error', reject);
  });

  const { tokens } = await oauth2Client.getToken(code);
  oauth2Client.setCredentials(tokens);
  fs.writeFileSync(tokenPath, JSON.stringify(tokens, null, 2));
  console.log(`Saved token to ${tokenPath}`);
}

function loadAuthorizedClient(profile, scopes) {
  const oauth2Client = createOAuthClient(scopes);
  const { tokenPath } = getProfilePaths(profile);
  if (!fs.existsSync(tokenPath)) {
    throw new Error(`Missing token file for ${profile}: ${tokenPath}`);
  }
  const tokens = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
  oauth2Client.setCredentials(tokens);
  return oauth2Client;
}

module.exports = {
  ROOT,
  AUTH_ROOT,
  getProfilePaths,
  runLocalAuthFlow,
  loadAuthorizedClient,
  google,
};
