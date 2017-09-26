import { expect } from 'chai';
import { getRowObjects } from '../../../app/reader/DocumentsTable';
import { DOCUMENTS_OR_COMMENTS_ENUM } from '../../../app/reader/constants';

// TODO: this spec causes the Travis karma build to time out (see #2858).
xdescribe('DocumentsTable', () => {
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

  it('in comments mode, omits rows for docs with no comments', () => {
    const documents = [
      { id: 12 },
      {
        id: 15,
        listComments: true
      },
      {
        id: 20,
        listComments: true
      }
    ];
    const annotationsPerDocument = {
      15: 'annotations',
      20: 'annotations'
    };
    const rowObjects = getRowObjects(documents, annotationsPerDocument, DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS);

    expect(rowObjects).to.deep.equal([
      {
        id: 15,
        listComments: true
      },
      {
        id: 15,
        listComments: true,
        isComment: true
      },
      {
        id: 20,
        listComments: true
      },
      {
        id: 20,
        listComments: true,
        isComment: true
      }
    ]);
  });
});
