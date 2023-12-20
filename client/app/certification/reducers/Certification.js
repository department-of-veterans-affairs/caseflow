import { update } from '../../util/ReducerUtil';

export const updateProgressBar = (state, action) => {
  return Object.assign({}, state, {
    currentSection: action.payload.currentSection,
    // reset some parts of state so we don't skip pages or end up in loops
    serverError: null,
    updateSucceeded: null,
    updateSuccesses: {},
    loading: false,
    erroredFields: null,
    scrollToError: false
  });
};

export const showValidationErrors = (state, action) => {
  return Object.assign({}, state, {
    erroredFields: action.payload.erroredFields,
    scrollToError: action.payload.scrollToError
  });
};

export const startUpdateCertification = (state) => {
  // setting the 'loading' attribute causes
  // a spinny spinner to appear over the continue
  // button
  // TODO: verify that this also disables the continue
  // button.
  return Object.assign({}, state, {
    loading: true
  });
};

export const handleServerError = (state) => {
  return Object.assign({}, state, {
    serverError: true,
    loading: false
  });
};

export const certificationUpdateSuccess = (state) => {
  return Object.assign({}, state, {
    updateSucceeded: true,
    loading: false
  });
};

export const confirmHearingUpdateSuccess = (state) => update(
  state,
  {
    updateSuccesses: {
      confirmHearing: { $set: true }
    }
  }
);

export const toggleCancellationModal = (state) => {
  let showModal = Boolean(state.showCancellationModal);

  return Object.assign({}, state, {
    showCancellationModal: !showModal
  });
};

export const clearErroredField = (fieldName, state) => {
  const newErroredFields = state.erroredFields || [];
  const index = newErroredFields.indexOf(fieldName);

  if (index !== -1) {
    newErroredFields.splice(index, 1);
  }

  return newErroredFields;
};
