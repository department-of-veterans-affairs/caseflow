// actions
export const CHANGE_VBMS_HEARING_DOCUMENT = 'CHANGE_VBMS_HEARING_DOCUMENT';
export const CHANGE_TYPE_OF_FORM9 = 'CHANGE_TYPE_OF_FORM9';
export const CHANGE_TYPE_OF_HEARING = 'CHANGE_TYPE_OF_HEARING';

// types of hearings
//
// TODO:
// on the backend, NO_HEARING_DESIRED
// should result in VIDEO being written to VACOLS,
// and HEARING_CANCELLED should result in a cancellation
// checkbox being checked, but the original hearing type
// should be undisturbed.
export const hearingTypes = {
  VIDEO: 'VIDEO',
  TRAVEL_BOARD: 'TRAVEL_BOARD',
  WASHINGTON_DC: 'WASHINGTON_DC',
  HEARING_TYPE_NOT_SPECIFIED: 'HEARING_TYPE_NOT_SPECIFIED',
  NO_HEARING_DESIRED: 'NO_HEARING_DESIRED',
  HEARING_CANCELLED: 'HEARING_CANCELLED'
};

// form9 values
export const form9Types = {
  FORMAL_FORM9: 'FORMAL_FORM9',
  INFORMAL_FORM9: 'INFORMAL_FORM9'
};
