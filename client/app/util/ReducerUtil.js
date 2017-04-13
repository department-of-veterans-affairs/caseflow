export default {
  changeFieldValue: (state, action) => ({
    ...state,
      [action.payload.field]: action.payload.value
  })
};
