export const mapDataToInitialState = function(props = {}) {
  return {
    veteran: {
      fileNumber: props.veteranFileNumber,
      formName: props.veteranFormName
    },
    intake: {
      formType: props.formType,
      receiptDate: props.receiptDate,
      sameOffice: props.sameOffice ? props.sameOffice : null,
      informalConference: props.informalConference ? props.informalConference : null,
      issues: props.issues,
      claimId: props.claimId
    }
  };
};

export const intakeEditReducer = (state = mapDataToInitialState()) => {
  return state;
};
