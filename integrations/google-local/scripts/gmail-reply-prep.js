const { loadAuthorizedClient, google } = require('./_shared');
const { findBestBody, headerMap, compactText } = require('./_gmail-utils');

const scopes = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
];

function normalizeSubject(subject = '') {
  if (!subject) return '';
  return /^re:/i.test(subject) ? subject : `Re: ${subject}`;
}

async function main() {
  const threadId = process.argv[2];
  if (!threadId) throw new Error('Provide a Gmail thread id.');

  const auth = loadAuthorizedClient('gmail-readonly', scopes);
  const gmail = google.gmail({ version: 'v1', auth });
  const profile = await gmail.users.getProfile({ userId: 'me' });
  const myEmail = profile.data.emailAddress || '';

  const res = await gmail.users.threads.get({ userId: 'me', id: threadId, format: 'full' });
  const thread = res.data;
  const messages = (thread.messages || []).map(msg => {
    const headers = headerMap(msg.payload?.headers || []);
    return {
      id: msg.id,
      threadId: msg.threadId,
      from: headers.from || '',
      to: headers.to || '',
      cc: headers.cc || '',
      subject: headers.subject || '',
      date: headers.date || '',
      messageId: headers['message-id'] || '',
      references: headers.references || '',
      inReplyTo: headers['in-reply-to'] || '',
      snippet: msg.snippet || '',
      bodyPreview: compactText(findBestBody(msg.payload), 1200)
    };
  });

  const latest = messages[messages.length - 1];
  if (!latest) throw new Error('Thread has no messages.');

  const replyTo = latest.from;
  const subject = normalizeSubject(latest.subject || messages[0]?.subject || '');

  const contextSummary = messages.map((m, idx) => ({
    order: idx + 1,
    from: m.from,
    date: m.date,
    snippet: m.snippet,
    bodyPreview: m.bodyPreview
  }));

  console.log(JSON.stringify({
    threadId: thread.id,
    myEmail,
    recommendedReplyTo: replyTo,
    recommendedSubject: subject,
    latestMessageId: latest.id,
    latestInternetMessageId: latest.messageId,
    referencesHeader: latest.references || latest.messageId || '',
    inReplyToHeader: latest.messageId || '',
    contextSummary,
    draftGuidance: {
      goal: 'Draft a reply grounded in the real thread context. Do not send automatically.',
      shouldSendAutomatically: false,
      notes: [
        'Use the latest customer message as the primary response target.',
        'Preserve thread context when drafting.',
        'Confirm any promises, refunds, shipment changes, or irreversible actions before sending.'
      ]
    }
  }, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify(err.response?.data || { error: err.message || String(err) }, null, 2));
  process.exit(1);
});
