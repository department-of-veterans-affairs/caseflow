export default {
  changeFieldValue: (state, action) => {
    let newState = Object.assign({}, state);

    newState[action.payload.field] = action.payload.value;

    return newState;
  }
};
