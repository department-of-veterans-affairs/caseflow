// TODO: make consts file, so these constants are
// shared throughout the application ()
const CHANGE_VBMS_HEARING_DOCUMENT = 'CHANGE_VBMS_HEARING_DOCUMENT';
const CHANGE_TYPE_OF_FORM9 = 'CHANGE_TYPE_OF_FORM9';
const CHANGE_TYPE_OF_HEARING = 'CHANGE_TYPE_OF_HEARING';

/*
 * This global reducer is called every time a state change is
 * made in the application using `.dispatch`. The state changes implemented here
 * are very simple. As they get more complicated and numerous,
 * these are conventionally broken out into separate "actions" files
 * that would live at client/app/actions/**.js.
 */
const certification = function(state, action) {
  switch (action.type) {
  case CHANGE_VBMS_HEARING_DOCUMENT:
    return Object.assign({}, state, {
      hearingDocumentIsInVbms: action.hearingDocumentIsInVbms
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
