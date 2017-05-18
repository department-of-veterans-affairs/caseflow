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
