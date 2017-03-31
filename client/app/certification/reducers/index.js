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

 const certification = function(state = initialState, action) {
   switch (action.type) {
   case Constants.CHANGE_REPRESENTATIVE_NAME:
     return Object.assign({}, state, {
       representativeName: action.payload.representativeName
     });
   case Constants.CHANGE_REPRESENTATIVE_TYPE:
     return Object.assign({}, state, {
       representativeType: action.payload.representativeType
     });
   case Constants.CHANGE_VBMS_HEARING_DOCUMENT:
     return Object.assign({}, state, {
       hearingDocumentIsInVbms: action.payload.hearingDocumentIsInVbms
     });
   case Constants.CHANGE_TYPE_OF_FORM9:
     return Object.assign({}, state, {
       form9Type: action.payload.form9Type
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

 export default certification;
