/* eslint-disable camelcase */
export const documents = [
  {
    id: 1,
    filename: 'doc1',
    content_url: '/document/2/pdf',
    received_at: '2017-01-02',
    category_medical: true,
    type: 'bva decision',
    tags: [
      {
        id: 1,
        text: 'mytag'
      }
    ]
  },
  {
    id: 2,
    filename: 'doc2',
    content_url: '/document/2/pdf',
    received_at: '2017-03-04',
    category_procedural: true,
    type: 'form 9',
    tags: [
      {
        id: 1,
        text: 'mytag'
      }
    ]
  }
];

/* eslint-enable camelcase */
