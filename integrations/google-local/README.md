# google-local

Local Gmail + Contacts read-only wrappers.

Goals:
- Keep auth separate from the main `gws` credential store
- Use least-privilege scopes
- Support read/search/retrieve workflows first

Planned wrapper auth stores:
- `auth/gmail-readonly/`
- `auth/contacts-readonly/`

Scripts:
- `scripts/Start-GoogleWrapperAuth.ps1`
- `scripts/Test-GmailRead.ps1`
- `scripts/Test-ContactsRead.ps1`
- `scripts/gmail-list-recent.js`
- `scripts/gmail-search.js`
- `scripts/gmail-get-message.js`
- `scripts/gmail-get-thread.js`
- `scripts/gmail-extract.js`
- `scripts/gmail-summarize-thread.js`
- `scripts/gmail-reply-prep.js`
- `scripts/gmail-classify-thread.js`
- `scripts/contacts-list.js`
- `scripts/contacts-search.js`

Operator entrypoint:
- `npm run google-local -- <command> [args]`

Examples:
- `npm run google-local -- gmail-list 5`
- `npm run google-local -- gmail-search "from:customer@example.com"`
- `npm run google-local -- gmail-summary <threadId>`
- `npm run google-local -- gmail-classify <threadId>`
- `npm run google-local -- gmail-reply-prep <threadId>`
- `npm run google-local -- contacts-search "shippo"`

Notes:
- Do not export or decrypt `gws` master credentials.
- Do not commit tokens or secrets.
