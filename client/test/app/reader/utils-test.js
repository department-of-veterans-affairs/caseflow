import { moveModel, isValidWholeNumber } from '../../../app/reader/utils';

describe('Reader utils', () => {
  describe('moveModel', () => {
    it('moves a model in the state', () => {
      const state = {
        editingAnnotations: {},
        annotations: {
          123: {
            comment: 'text'
          }
        }
      };

      const newState = moveModel(
        state,
        ['annotations'],
        ['editingAnnotations'],
        123
      );

      expect(newState).toEqual({
        editingAnnotations: {
          123: {
            comment: 'text'
          }
        },
        annotations: {}
      });
    });
  });
  describe('isValidWholeNumber', () => {

    /* eslint-disable no-unused-expressions */
    it('checks if number is a valid number', () => {
      expect(isValidWholeNumber(10)).toBe(true);
      expect(isValidWholeNumber('er')).toBe(false);
      expect(isValidWholeNumber('10')).toBe(true);
      expect(isValidWholeNumber('-10abc')).toBe(false);
    });

    /* eslint-disable no-unused-expressions */
  });
});
