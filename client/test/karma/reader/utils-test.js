import { expect } from 'chai';
import { getAnnotationByDocumentId, moveModel } from '../../../app/reader/utils';

describe('Reader utils', () => {
  describe('moveModel', () => {
    it('moves a model in the state', () => {
      const state = {
        ui: {
          editingAnnotations: {}
        },
        annotations: {
          123: {
            comment: 'text'
          }
        }
      };

      const newState = moveModel(
        state,
        ['annotations'],
        ['ui', 'editingAnnotations'],
        123
      );

      expect(newState).to.deep.equal({
        ui: {
          editingAnnotations: {
            123: {
              comment: 'text'
            }
          }
        },
        annotations: {}
      });
    });
  });
});
