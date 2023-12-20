import _ from 'lodash';
import { newContext } from 'immutability-helper';

export const update = newContext();

update.extend('$unset', (keyToUnset, obj) => obj && _.omit(obj, keyToUnset));

export default {
  changeFieldValue: (state, action) => ({
    ...state,
    [action.payload.field]: action.payload.value
  }),

  changeObjectInArray: (array, action) => {
    return array.map((object, index) => {
      if (index !== action.index) {
        // This isn't the item we care about - keep it as-is
        return object;
      }

      // Otherwise, this is the one we want - return an updated value
      return {
        ...object,
        ...action.values
      };
    });
  }
};
