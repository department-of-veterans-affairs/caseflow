// TODO: make consts file
const CHANGE_VBMS_HEARING_DOCUMENT = 'CHANGE_VBMS_HEARING_DOCUMENT';
const CHANGE_TYPE_OF_FORM9 = 'CHANGE_TYPE_OF_FORM9';
const CHANGE_TYPE_OF_HEARING = 'CHANGE_TYPE_OF_HEARING';


const certification = function(state, action) {
  console.log(state, action);
  switch (action.type) {
  case CHANGE_VBMS_HEARING_DOCUMENT:
    return Object.assign({}, state, {
      hearingDocumentInVbms: action.exists
    });
  case CHANGE_TYPE_OF_FORM9:
    return Object.assign({}, state, {
      form9Type: action.form9Type
    });
  case CHANGE_TYPE_OF_HEARING:
    return Object.assign({}, state, {
      hearingType: action.hearingType
    });
  default:
    return state;
  }
};

export default certification;
