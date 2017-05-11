import { expect } from 'chai';
import { getAnnotationByDocumentId } from '../../../app/reader/utils';

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
          300: {
            id: 300,
            comment: 'different doc',
            documentId: 800
          }
        },
        ui: {
          pendingAnnotations: {
            'temp-guid': {
              id: 'temp-guid',
              comment: 'pending annotation',
              documentId
            }
          }
        }
      };

      expect(getAnnotationByDocumentId(state, documentId)).to.deep.equal([
        {
          id: 100,
          comment: 'edited',
          documentId,
          editing: true
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
