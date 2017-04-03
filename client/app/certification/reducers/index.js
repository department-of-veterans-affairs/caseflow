import * as Constants from '../constants/constants';

/*
* This global reducer is called every time a state change is
* made in the application using `.dispatch`. The state changes implemented here
* are very simple. As they get more complicated and numerous,
* these are conventionally broken out into separate "actions" files
* that would live at client/app/actions/**.js.
*/

const initialState = {
  hearingDocumentIsInVbms: null,
  form9Type: null,
  hearingType: null,
  certifyingOffice: null,
  certifyingUsername: null,
  certifyingOfficialName: null,
  certifyingOfficialTitle: null,
  certificationDate: null
};

// TODO: break this out into a separate actions file.
const updateRepresentativeType = (state, action) => {
  const update = {};

  update.representativeType = action.payload.representativeType;
  // if we changed the type to something other than "Other",
  // erase the other representative type if it was specified.
  if (state.representativeType !== Constants.representativeTypes.OTHER) {
    update.otherRepresentativeType = null;
  }

  return Object.assign({}, state, update);
};

export const certificationReducers = function(state = initialState, action = {}) {
  switch (action.type) {
  case Constants.CHANGE_REPRESENTATIVE_NAME:
    return Object.assign({}, state, {
      representativeName: action.payload.representativeName
    });
  case Constants.CHANGE_REPRESENTATIVE_TYPE: {
    return updateRepresentativeType(state, action);
  }
  case Constants.CHANGE_OTHER_REPRESENTATIVE_TYPE: {
    return Object.assign({}, state, {
      otherRepresentativeType: action.payload.otherRepresentativeType
    });
  }
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
  case Constants.CHANGE_CERTIFYING_OFFICIAL:
    return Object.assign({}, state, {
      certifyingOffice: action.payload.certifyingOffice
    });
  case Constants.CHANGE_CERTIFYING_USERNAME:
    return Object.assign({}, state, {
      certifyingUsername: action.payload.certifyingUsername
    });
  case Constants.CHANGE_CERTIFYING_OFFICIAL_NAME:
    return Object.assign({}, state, {
      certifyingOfficialName: action.payload.certifyingOfficialName
    });
  case Constants.CHANGE_CERTIFYING_OFFICIAL_TITLE:
    return Object.assign({}, state, {
      certifyingOfficialTitle: action.payload.certifyingOfficialTitle
    });
  case Constants.CHANGE_CERTIFICATION_DATE:
    return Object.assign({}, state, {
      certificationDate: action.payload.certificationDate
    });
  default:
    return state;
  }
};

export const mapDataToInitialState = function(state) {
  return {
    form9Match: state.appeal['form9_match?'],
    form9Date: state.appeal.form9_date,
    nodMatch: state.appeal['nod_match?'],
    nodDate: state.appeal.nod_date,
    socMatch: state.appeal['soc_match?'],
    socDate: state.appeal.soc_date,
    documentsMatch: state.appeal['documents_match?'],

    /* TODO: add ssoc_match and ssoc_dates */
    vbmsId: state.appeal.vbms_id,
    veteranName: state.appeal.veteran_name,
    certificationStatus: state.certification_status,
    vacolsId: state.vacols_id
  };
};
