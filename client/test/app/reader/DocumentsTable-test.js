import { getRowObjects } from '../../../app/reader/DocumentsTable';

describe('DocumentsTable', () => {
  it(
    'in documents mode, only adds comment rows for docs which have listComments set',
    () => {
      const documents = [
        {
          id: 12,
          listComments: true
        },
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

      expect(rowObjects).toEqual([
        {
          id: 12,
          listComments: true
        },
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
        },
      ]);
    }
  );
});
