const { spawnSync } = require('child_process');
const path = require('path');

const root = __dirname;

const commands = {
  'gmail-list': ['gmail-list-recent.js'],
  'gmail-search': ['gmail-search.js'],
  'gmail-message': ['gmail-get-message.js'],
  'gmail-thread': ['gmail-get-thread.js'],
  'gmail-extract': ['gmail-extract.js'],
  'gmail-summary': ['gmail-summarize-thread.js'],
  'gmail-classify': ['gmail-classify-thread.js'],
  'gmail-reply-prep': ['gmail-reply-prep.js'],
  'contacts-list': ['contacts-list.js'],
  'contacts-search': ['contacts-search.js']
};

function usage() {
  console.log(`Usage: node scripts/google-local.js <command> [args]\n\nCommands:\n  gmail-list [maxResults]\n  gmail-search <query>\n  gmail-message <messageId>\n  gmail-thread <threadId>\n  gmail-extract <message|thread> <id>\n  gmail-summary <threadId>\n  gmail-classify <threadId>\n  gmail-reply-prep <threadId>\n  contacts-list [pageSize]\n  contacts-search <query>`);
}

const cmd = process.argv[2];
if (!cmd || !commands[cmd]) {
  usage();
  process.exit(cmd ? 1 : 0);
}

const scriptName = commands[cmd][0];
const scriptPath = path.join(root, scriptName);
const args = process.argv.slice(3);
const result = spawnSync(process.execPath, [scriptPath, ...args], { stdio: 'inherit' });
process.exit(result.status || 0);
