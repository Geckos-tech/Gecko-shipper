function looksAutomatedAddress(value = '') {
  const v = value.toLowerCase();
  return /(^|[<\s])(no-?reply|noreply|do-?not-?reply|mailer-daemon|postmaster|notification|notifications|support@usps|ecns@usps)/.test(v);
}

function looksAutomatedSubject(value = '') {
  const v = value.toLowerCase();
  return /(payment confirmation|order confirmation|shipping confirmation|label created|receipt|invoice|statement|password reset|verify your email|tracking update)/.test(v);
}

function looksCustomerInquiry(text = '') {
  const v = text.toLowerCase();
  return /(can you|could you|i need|i have a question|question about|when will|where is my|where is the|please help|issue with|problem with|refund|replace|wrong address|update my address|tracking says|thanks so much|thank you for your help)/.test(v);
}

function classifyThread(summary) {
  const participants = summary.participants || [];
  const latest = summary.latestMessage || {};
  const body = latest.bodyPreview || '';
  const from = latest.from || '';
  const subject = summary.subject || latest.subject || '';
  const fromLower = from.toLowerCase();
  const knownSystemSender = /usps|fedex|ups|shopify|amazon|paypal/.test(fromLower);

  const automatedSignals = [
    looksAutomatedAddress(from),
    looksAutomatedSubject(subject),
    /this is an automated email/i.test(body),
    knownSystemSender
  ].filter(Boolean).length;

  const customerSignals = [
    !looksAutomatedAddress(from) && !knownSystemSender,
    looksCustomerInquiry(body),
    /@/.test(from) && !knownSystemSender && !looksAutomatedAddress(from)
  ].filter(Boolean).length;

  let category = 'unknown';
  if (automatedSignals >= 2 && customerSignals === 0) category = 'automated';
  else if (customerSignals >= 2) category = 'customer';
  else if (automatedSignals >= 1 && customerSignals >= 1) category = 'mixed';

  const shouldReply = category === 'customer' || category === 'mixed';

  return {
    category,
    shouldReply,
    automatedSignals,
    customerSignals,
    reasons: [
      automatedSignals ? 'Contains automated-email indicators' : null,
      customerSignals ? 'Contains customer-conversation indicators' : null
    ].filter(Boolean)
  };
}

module.exports = {
  classifyThread,
};
