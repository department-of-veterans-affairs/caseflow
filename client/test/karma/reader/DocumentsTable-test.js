import { expect } from 'chai';
import { getRowObjects } from '../../../app/reader/DocumentsTable';
import { DOCUMENTS_OR_COMMENTS_ENUM } from '../../../app/reader/constants';

describe('DocumentsTable', () => {
  it('selects all documents with comments in comments mode', () => {
    const documents = [
      { id: 12 },
      { id: 15 },
      { id: 20 }
    ];
    const annotationsPerDocument = {
      15: 'annotations',
      20: 'annotations'
    };
    const rowObjects = getRowObjects(documents, annotationsPerDocument, DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS);

    expect(rowObjects).to.deep.equal([
      { id: 15 },
      {
        id: 15,
        isComment: true
      },
      { id: 20 },
      {
        id: 20,
        isComment: true
      }
    ]);
  });

  it('in documents mode, only adds comment rows for docs with listComments set', () => {
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
    const rowObjects = getRowObjects(documents, annotationsPerDocument, DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS);

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
