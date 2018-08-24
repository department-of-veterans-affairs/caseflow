export const mapDataToInitialState = function(props = {}) {
  return {
    formType: props.formType,
    review: props.review
  };
};

export const intakeEditReducer = (state = mapDataToInitialState()) => {
  return state;
};
