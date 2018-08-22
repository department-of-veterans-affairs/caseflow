export const mapDataToInitialState = function(props = {}) {
  return {
    veteran: props.veteran,
    formType: props.formType,
    intake: props.intake
  };
};

export const intakeEditReducer = (state = mapDataToInitialState()) => {
  return state;
};
