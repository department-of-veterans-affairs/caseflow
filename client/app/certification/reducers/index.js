 import * as Constants from '../constants/constants';

/*
 * This global reducer is called every time a state change is
 * made in the application using `.dispatch`. The state changes implemented here
 * are very simple. As they get more complicated and numerous,
 * these are conventionally broken out into separate "actions" files
 * that would live at client/app/actions/**.js.
 */
 const certification = function(state, action) {
   switch (action.type) {
   case Constants.CHANGE_VBMS_HEARING_DOCUMENT:
     return Object.assign({}, state, {
       hearingDocumentIsInVbms: action.hearingDocumentIsInVbms
     });
   case Constants.CHANGE_TYPE_OF_FORM9:
     return Object.assign({}, state, {
       form9Type: action.form9Type
     });
   case Constants.CHANGE_TYPE_OF_HEARING:
     return Object.assign({}, state, {
       hearingType: action.hearingType
     });
   default:
     return state;
   }
 };

 export default certification;
