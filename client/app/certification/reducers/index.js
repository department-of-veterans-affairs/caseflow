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
   hearingType: null
 };

 export const certificationReducers = function(state = initialState, action) {
   switch (action.type) {
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
      /* TODO: add ssoc_match and ssoc_dates */
      vbmsId: state.appeal.vbms_id,
      veteranName: state.appeal.veteran_name,
      certificationStatus: state.certification_status,
      vacolsId: state.vacols_id
    };
 };
