export const dispositions = ['granted', 'partially_granted', 'denied'];

export const dispositionOptions = [
  { displayText: 'Grant all issues', value: 'granted' },
  {
    displayText: 'Grant a partial switch',
    value: 'partially_granted',
    help: 'e.g. if the Board is only granting a few issues',
  },
  { displayText: 'Deny all issues', value: 'denied' },
];
