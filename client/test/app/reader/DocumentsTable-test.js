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
          fileSize: expect.any(Number),
          id: 12,
          listComments: true
        },
        {
          fileSize: expect.any(Number),
          id: 15,
          listComments: true
        },
        {
          fileSize: expect.any(Number),
          id: 15,
          listComments: true,
          isComment: true
        },
        {
          fileSize: expect.any(Number),
          id: 20,
        },
      ]);
    }
  );
});
