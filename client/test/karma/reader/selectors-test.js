import { expect } from 'chai';
import { makeGetAnnotationsByDocumentId } from '../../../app/reader/selectors';

describe('Reader utils', () => {
  describe('getAnnotationByDocumentId', () => {
    it('gets annotations', () => {
      const documentId = 700;
      const state = {
        editingAnnotations: {
          100: {
            id: 100,
            comment: 'edited',
            documentId
          },
          300: {
            id: 300,
            comment: 'wrong doc',
            documentId: 800
          }
        },
        annotations: {
          100: {
            id: 100,
            comment: 'original',
            documentId
          },
          200: {
            id: 200,
            comment: 'original 2',
            documentId
          },
          250: {
            id: 250,
            comment: 'original 3',
            documentId
          },
          270: {
            id: 270,
            comment: 'should be deleted',
            documentId,
            pendingDeletion: true
          },
          300: {
            id: 300,
            comment: 'different doc',
            documentId: 800
          }
        },
        ui: {
          pendingEditingAnnotations: {
            250: {
              id: 250,
              comment: 'pending edit',
              documentId
            }
          },
          pendingAnnotations: {
            'temp-guid': {
              id: 'temp-guid',
              comment: 'pending annotation',
              documentId
            }
          }
        }
      };

      expect(makeGetAnnotationsByDocumentId(state)(documentId)).to.deep.equal([
        {
          id: 100,
          comment: 'edited',
          documentId,
          editing: true
        },
        {
          id: 250,
          comment: 'pending edit',
          documentId
        },
        {
          id: 200,
          comment: 'original 2',
          documentId
        },
        {
          id: 'temp-guid',
          comment: 'pending annotation',
          documentId
        }
      ]);
    });
  });
});
