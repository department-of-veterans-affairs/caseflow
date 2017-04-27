export const updateProgressBar = (state, action) => {
  return Object.assign({}, state, {
    currentSection: action.payload.currentSection,
    // reset some parts of state so we don't skip pages or end up in loops
    updateFailed: null,
    updateSucceeded: null,
    loading: false
  });
};

export const onContinueClickFailed = (state, action) => {
  return Object.assign({}, state, {
    continueClicked: action.payload.continueClicked
  });
};

export const onContinueClickSuccess = (state, action) => {
  return Object.assign({}, state, {
    continueClicked: action.payload.continueClicked
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

export const certificationUpdateFailure = (state) => {
  return Object.assign({}, state, {
    updateFailed: true,
    loading: false
  });
};

export const certificationUpdateSuccess = (state) => {
  return Object.assign({}, state, {
    updateSucceeded: true,
    loading: false
  });
};
