import * as Constants from '../constants/constants';
import * as ConfirmCaseDetailsReducers from './ConfirmCaseDetails';
import * as CertificationReducers from './Certification';

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
      hearingPreference: null
    });
  case Constants.CHANGE_TYPE_OF_FORM9:
    return Object.assign({}, state, {
      form9Type: action.payload.form9Type,
      // If we change the answer for the form 9 type question,
      // also wipe the state for the type of hearing the Veteran prefers,
      // since the previous answer is no longer valid.
      hearingPreference: null
    });
  case Constants.CHANGE_TYPE_OF_HEARING:
    return Object.assign({}, state, {
      hearingPreference: action.payload.hearingPreference
    });
  case Constants.CHANGE_SIGN_AND_CERTIFY_FORM:
    return changeSignAndCertifyForm(state, action);

  // Certification
  // ==================
  //
  // TODO: rename this to something else, it's more like a Page Load action now.
  case Constants.UPDATE_PROGRESS_BAR:
    return CertificationReducers.updateProgressBar(state, action);
  case Constants.RESET_STATE:
    return Object.assign({}, state, {
      // reset some parts of state so we don't skip pages or end up in loops
      updateFailed: null,
      updateSucceeded: null,
      loading: false
    });
  case Constants.ON_CONTINUE_CLICK_FAILED:
    return CertificationReducers.onContinueClickFailed(state, action);
  case Constants.ON_CONTINUE_CLICK_SUCCESS:
    return CertificationReducers.onContinueClickSuccess(state, action);
  case Constants.CERTIFICATION_UPDATE_REQUEST:
    return CertificationReducers.startUpdateCertification(state);
  case Constants.CERTIFICATION_UPDATE_FAILURE:
    return CertificationReducers.certificationUpdateFailure(state);
  case Constants.CERTIFICATION_UPDATE_SUCCESS:
    return CertificationReducers.certificationUpdateSuccess(state);

  default:
    return state;
  }
};
export default certificationReducers;

export const hearingDocumentIsInVbmsToStr = function(hearingDocumentIsInVbms) {
  switch (hearingDocumentIsInVbms) {
  case true:
    return Constants.vbmsHearingDocument.FOUND;
  case false:
    return Constants.vbmsHearingDocument.NOT_FOUND;
  default:
    return null;
  }
};

export const mapDataToInitialState = function(state) {
  return {
    // TODO alex: fix bug where other representative type won't
    // come down from the server, dagnabbit.
    representativeType: state.representative_type,
    representativeName: state.representative_name,
    form9Match: state.appeal['form9_match?'],
    form9Date: state.appeal.serialized_form9_date,
    nodMatch: state.appeal['nod_match?'],
    nodDate: state.appeal.serialized_nod_date,
    socMatch: state.appeal['soc_match?'],
    socDate: state.appeal.serialized_soc_date,
    ssocDatesWithMatches: state.appeal.ssoc_dates_with_matches,
    documentsMatch: state.appeal['documents_match?'],
    certificationId: state.id,
    vbmsId: state.appeal.vbms_id,
    veteranName: state.appeal.veteran_name,
    certificationStatus: state.certification_status,
    vacolsId: state.vacols_id,
    hearingDocumentIsInVbms: hearingDocumentIsInVbmsToStr(state.hearing_change_doc_found_in_vbms),
    hearingPreference: state.hearing_preference,
    form9Type: state.form9_type,
    certifyingOffice: state.form8.certifying_office,
    certifyingUsername: state.form8.certifying_username,
    certificationDate: state.form8.certification_date
  };
};
