import { expect } from 'chai';
import { moveModel, isValidNum } from '../../../app/reader/utils';

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
  describe('isValidNum', () => {

    /* eslint-disable no-unused-expressions */
    it('checks if number is a valid number', () => {
      expect(isValidNum(10)).to.be.true;
      expect(isValidNum('er')).to.be.false;
      expect(isValidNum('10')).to.be.true;
      expect(isValidNum('-10abc')).to.be.false;
    });

    /* eslint-disable no-unused-expressions */
  });
});
