import { expect } from 'chai';
import { moveModel, isValidWholeNumber } from '../../../app/reader/utils';

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
  describe('isValidWholeNumber', () => {

    /* eslint-disable no-unused-expressions */
    it('checks if number is a valid number', () => {
      expect(isValidWholeNumber(10)).to.be.true;
      expect(isValidWholeNumber('er')).to.be.false;
      expect(isValidWholeNumber('10')).to.be.true;
      expect(isValidWholeNumber('-10abc')).to.be.false;
    });

    /* eslint-disable no-unused-expressions */
  });
});
