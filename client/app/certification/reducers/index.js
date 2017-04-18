import * as Constants from '../constants/constants';
import * as ConfirmCaseDetailsReducers from '../ConfirmCaseDetails';

/*
* This global reducer is called every time a state change is
* made in the application using `.dispatch`. The state changes implemented here
* are very simple. As they get more complicated and numerous,
* these are conventionally broken out into separate "actions" files
* that would live at client/app/actions/**.js.
*/


// TODO: break this out into a reducers/SignAndCertify.jsx
const changeSignAndCertifyForm = (state, action) => {
  const update = {};

  for (const key of Object.keys(action.payload)) {
    update[key] = action.payload[key];
  }

  return Object.assign({}, state, update);
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


// TODO: is this meant to be something like a schema?
// it's too similar to the object in "mapDataToInitialState".
const initialState = {
  documentsMatch: null,
  form9Match: null,
  socMatch: null,
  representativeType: null,
  representativeName: null,
  otherRepresentativeType: null
};

export const certificationReducers = function(state = initialState, action = {}) {
  switch (action.type) {

  // ConfirmCaseDetails
  // ==================
  case Constants.CHANGE_REPRESENTATIVE_NAME:
    return ConfirmCaseDetailsReducers.changeRepresentativeName(state, action);
  case Constants.CHANGE_REPRESENTATIVE_TYPE:
    return ConfirmCaseDetailsReducers.changeRepresentativeType(state, action);
  case Constants.CHANGE_OTHER_REPRESENTATIVE_TYPE:
    return ConfirmCaseDetailsReducers.changeOtherRepresentativeType(state, action);

  // ConfirmHearing
  // ==================
  // TODO: break these out into reducers/ConfirmHearing.js
  case Constants.CHANGE_VBMS_HEARING_DOCUMENT:
    return Object.assign({}, state, {
      hearingDocumentIsInVbms: action.payload.hearingDocumentIsInVbms,
      // If we change the answer for the hearing doc in VBMS question,
      // also wipe the state for the type of hearing the Veteran prefers,
      // since the previous answer is no longer valid.
      hearingType: null
    });
  case Constants.CHANGE_TYPE_OF_FORM9:
    return Object.assign({}, state, {
      form9Type: action.payload.form9Type,
      // If we change the answer for the form 9 type question,
      // also wipe the state for the type of hearing the Veteran prefers,
      // since the previous answer is no longer valid.
      hearingType: null
    });
  case Constants.CHANGE_TYPE_OF_HEARING:
    return Object.assign({}, state, {
      hearingType: action.payload.hearingType
    });
  case Constants.CHANGE_SIGN_AND_CERTIFY_FORM:
    return changeSignAndCertifyForm(state, action);

  // Certification
  // ==================
  // These reducer actions are used by a few different pages,
  // so they can stay in the index.
  //
  // TODO: rename this to something else, it's more like a Page Load action now.
  case Constants.UPDATE_PROGRESS_BAR:
    return Object.assign({}, state, {
      currentSection: action.payload.currentSection,
      // reset some parts of state so we don't skip pages or end up in loops
      updateFailed: null,
      updateSucceeded: null,
      loading: false
    });
  case Constants.FAILED_VALIDATION:
    return Object.assign({}, state, {
      invalidFields: action.payload.invalidFields,
      validationFailed: action.payload.validationFailed
    });
  case Constants.CERTIFICATION_UPDATE_REQUEST:
    return startUpdateCertification(state, action);
  case Constants.CERTIFICATION_UPDATE_FAILURE:
    return Object.assign({}, state, {
      updateFailed: true,
      loading: false
    });
  case Constants.CERTIFICATION_UPDATE_SUCCESS:
    return Object.assign({}, state, {
      updateSucceeded: true,
      loading: false
    });

  default:
    return state;
  }
};

export const mapDataToInitialState = function(state) {
  return {
    // TODO alex: fix bug where other representative type won't
    // come down from the server, dagnabbit.
    representativeType: state.representative_type,
    representativeName: state.representative_name,
    form9Match: state.appeal['form9_match?'],
    form9Date: state.appeal.form9_date,
    nodMatch: state.appeal['nod_match?'],
    nodDate: state.appeal.nod_date,
    socMatch: state.appeal['soc_match?'],
    socDate: state.appeal.soc_date,
    ssocDatesWithMatches: state.appeal.ssoc_dates_with_matches,
    documentsMatch: state.appeal['documents_match?'],
    certificationId: state.id,
    vbmsId: state.appeal.vbms_id,
    veteranName: state.appeal.veteran_name,
    certificationStatus: state.certification_status,
    vacolsId: state.vacols_id,

    certifyingOffice: state.form8.certifying_office,
    certifyingUsername: state.form8.certifying_username,
    certificationDate: state.form8.certification_date
  };
};
