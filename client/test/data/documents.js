/* eslint-disable camelcase */
export const documents = [
  {
    id: 1,
    filename: 'doc1',
    received_at: '01/02/2017',
    category_medical: true,
    type: 'bva decision',
    tags: []
  },
  {
    id: 2,
    filename: 'doc2',
    received_at: '03/04/2017',
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
