import { expect } from 'chai';
import { makeGetAnnotationsByDocumentId, docListIsFiltered } from '../../../app/reader/selectors';

describe('Reader utils', () => {
  describe('docListIsFiltered', () => {
    it('returns false when the list has not been filtered', () => {
      const state = {
        documents: {
          1: {},
          3: {},
          5: {}
        },
        ui: {
          filteredDocIds: [1, 3, 5],
          docFilterCriteria: {
            searchQuery: ''
          }
        }
      };

      expect(docListIsFiltered(state)).to.equal(false);
    });

    it('returns true when there is a search query', () => {
      const state = {
        documents: {
          1: {},
          3: {},
          5: {}
        },
        ui: {
          filteredDocIds: [1, 3, 5],
          docFilterCriteria: {
            searchQuery: 'something that matches all docs'
          }
        }
      };

      expect(docListIsFiltered(state)).to.equal(true);
    });

    it('returns true when there is a category filter', () => {
      const state = {
        documents: {
          1: {},
          3: {},
          5: {}
        },
        ui: {
          filteredDocIds: [1, 3, 5],
          docFilterCriteria: {
            searchQuery: '',
            category: {
              procedural: true
            }
          }
        }
      };

      expect(docListIsFiltered(state)).to.equal(true);
    });

    it('returns true when there is a tag filter', () => {
      const state = {
        documents: {
          1: {},
          3: {},
          5: {}
        },
        ui: {
          filteredDocIds: [1, 3, 5],
          docFilterCriteria: {
            searchQuery: '',
            tag: {
              'some tag': true
            }
          }
        }
      };

      expect(docListIsFiltered(state)).to.equal(true);
    });
  });

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
