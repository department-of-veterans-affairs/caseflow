export const mapDataToInitialState = function(props = {}) {
  return {
    veteran: {
      fileNumber: props.veteranFileNumber,
      formName: props.veteranFormName
    }
  };
};

export const intakeEditReducer = (state = mapDataToInitialState()) => {
  return state;
};
