import { expect } from 'chai';
import { getRowObjects } from '../../../app/reader/DocumentsTable';

describe('DocumentsTable', () => {
  it('in documents mode, only adds comment rows for docs which have comments and listComments set', () => {
    const documents = [
      { id: 12 },
      {
        id: 15,
        listComments: true
      },
      { id: 20 }
    ];
    const annotationsPerDocument = {
      15: 'annotations',
      20: 'annotations'
    };
    const rowObjects = getRowObjects(documents, annotationsPerDocument);

    expect(rowObjects).to.deep.equal([
      { id: 12 },
      {
        id: 15,
        listComments: true
      },
      {
        id: 15,
        listComments: true,
        isComment: true
      },
      { id: 20 }
    ]);
  });
});
