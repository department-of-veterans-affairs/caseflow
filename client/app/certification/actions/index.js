const CHANGE_VBMS_HEARING_DOCUMENT = 'CHANGE_VBMS_HEARING_DOCUMENT';
const CHANGE_TYPE_OF_FORM9 = 'CHANGE_TYPE_OF_FORM9';
const CHANGE_TYPE_OF_HEARING = 'CHANGE_TYPE_OF_HEARING';


/*
Usage:
store.dispatch(vbmsHearingDocExists(true));
store.dispatch(hasFormalForm9(false))
store.dispatch(changeHearingType('BVA'))
 */

const vbmsHearingDocExists = (exists) => {
  debugger;
  return {
    type: CHANGE_VBMS_HEARING_DOCUMENT,
    hearingDocumentIsInVbms: exists
  };
};

const hasFormalForm9 = (form9Type) => {
  return {
    type: CHANGE_TYPE_OF_FORM9,
    form9Type: form9Type
  };
};

const changeHearingType = (hearingType) => {
  /*
  Hearing type should be one of:
  "TRAVEL_BOARD",
  "VIDEO",
  "BVA",
  "NO_HEARING_DESIRED",
  "NO_HEARING_SELECTION"
   */
  return {
    type: CHANGE_TYPE_OF_HEARING,
    hearingType
  };
};

export { vbmsHearingDocExists,
  hasFormalForm9,
  changeHearingType
};


