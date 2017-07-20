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
  otherRepresentativeType: null,
  serverError: false,
  organizationName: ''
};

export const certificationReducers = function(state = initialState, action = {}) {
  switch (action.type) {

  // ConfirmCaseDetails
  // ==================
  case Constants.CHANGE_REPRESENTATIVE_NAME:
    return ConfirmCaseDetailsReducers.changeRepresentativeName(state, action);
  case Constants.CHANGE_ORGANIZATION_NAME:
    return ConfirmCaseDetailsReducers.changeOrganizationName(state, action);
  case Constants.CHANGE_REPRESENTATIVE_TYPE:
    return ConfirmCaseDetailsReducers.changeRepresentativeType(state, action);
  case Constants.CHANGE_OTHER_REPRESENTATIVE_TYPE:
    return ConfirmCaseDetailsReducers.changeOtherRepresentativeType(state, action);
  case Constants.CHANGE_POA_MATCHES:
    return ConfirmCaseDetailsReducers.changePoaMatches(state, action);
  case Constants.CHANGE_POA_CORRECT_LOCATION:
    return ConfirmCaseDetailsReducers.changePoaCorrectLocation(state, action);

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
      updateSucceeded: null,
      loading: false,
      showCancellationModal: false
    });

  case Constants.SHOW_VALIDATION_ERRORS:
    return CertificationReducers.showValidationErrors(state, action);
  case Constants.CERTIFICATION_UPDATE_REQUEST:
    return CertificationReducers.startUpdateCertification(state);
  case Constants.HANDLE_SERVER_ERROR:
    return CertificationReducers.handleServerError(state);
  case Constants.CERTIFICATION_UPDATE_SUCCESS:
    return CertificationReducers.certificationUpdateSuccess(state);
  case Constants.TOGGLE_CANCELLATION_MODAL:
    return CertificationReducers.
      toggleCancellationModal(state, action);


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

export const poaMatchesToStr = function(poaMatches) {
  switch (poaMatches) {
  case true:
    return Constants.poaMatches.MATCH;
  case false:
    return Constants.poaMatches.NO_MATCH;
  default:
    return null;
  }
};

// poaCorrectLocation/poaCorrectInVacols/poaCorrectinBGS will all be null if poaMatches is true
// if poaMatches is false, either one of poaCorrectInVacols or poaCorrectInBgs will be true, or
// they will both be false.
// poaCorrectInVacols and poaCorrectInBGs should never both be true
export const poaCorrectLocationToStr = function(poaCorrectInVacols, poaCorrectInBgs) {
  if (poaCorrectInVacols === true) {
    return Constants.poaCorrectLocation.VACOLS;
  } else if (poaCorrectInBgs === true) {
    return Constants.poaCorrectLocation.VBMS;
  } else if (poaCorrectInVacols === false && poaCorrectInBgs === false) {
    return null;
  }

  return null;
};

const certifyingOfficialTitle = function(title) {
  if (!Object.values(Constants.certifyingOfficialTitles).includes(title)) {
    return Constants.certifyingOfficialTitles.OTHER;
  }

  return title;
};

const certifyingOfficialTitleOther = function(title) {
  if (!Object.values(Constants.certifyingOfficialTitles).includes(title)) {
    return title;
  }
};

const parseDocumentFromApi = (doc = {}, index) => ({
  name: index ? `${doc.type} ${index}` : doc.type,
  vacolsDate: doc.serialized_vacols_date,
  vbmsDate: doc.serialized_receipt_date,
  isMatching: doc['matching?'],
  isExactlyMatching: doc.serialized_vacols_date === doc.serialized_receipt_date
});

export const mapDataToInitialState = (certification, form9PdfPath) => ({
  bgsRepresentativeType: certification.bgs_representative_type,
  bgsRepresentativeName: certification.bgs_representative_name,
  bgsPoaAddressFound: certification['bgs_rep_address_found?'],
  vacolsRepresentativeType: certification.vacols_representative_type,
  vacolsRepresentativeName: certification.vacols_representative_name,
  representativeType: certification.representative_type,
  representativeName: certification.representative_name,
  organizationName: certification.organizationName,
  poaMatches: poaMatchesToStr(certification.poa_matches),
  poaCorrectLocation: poaCorrectLocationToStr(certification.poa_correct_in_vacols, certification.poa_correct_in_bgs),
  nod: parseDocumentFromApi(certification.appeal.nod),
  soc: parseDocumentFromApi(certification.appeal.soc),
  form9: parseDocumentFromApi(certification.appeal.form9),
  ssocs: (certification.appeal.ssocs || []).map((ssoc, i) => parseDocumentFromApi(ssoc, i + 1)),
  documentsMatch: certification.appeal['documents_match?'],
  certificationId: certification.id,
  vbmsId: certification.appeal.vbms_id,
  veteranName: certification.appeal.veteran_name,
  certificationStatus: certification.certification_status,
  vacolsId: certification.vacols_id,
  hearingDocumentIsInVbms: hearingDocumentIsInVbmsToStr(certification.hearing_change_doc_found_in_vbms),
  hearingPreference: certification.hearing_preference,
  form9Type: certification.form9_type,
  form9PdfPath,
  certifyingOffice: certification.certifying_office,
  certifyingUsername: certification.certifying_username,
  certificationDate: certification.certification_date,
  certifyingOfficialName: certification.certifying_official_name,
  certifyingOfficialTitle: certifyingOfficialTitle(certification.certifying_official_title),
  certifyingOfficialTitleOther: certifyingOfficialTitleOther(certification.certifying_official_title)
});
