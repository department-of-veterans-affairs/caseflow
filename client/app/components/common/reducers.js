import { ACTIONS } from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {};

const commonComponentsReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_REGIONAL_OFFICES:
    return update(state, {
      regionalOffices: {
        $set: action.payload.regionalOffices
      }
    });
  case ACTIONS.REGIONAL_OFFICE_CHANGE:
    return update(state, {
      selectedRegionalOffice: {
        $set: action.payload.regionalOffice
      }
    });
  case ACTIONS.RECEIVE_HEARING_DATES:
    return update(staet, {
      hearingDates: {
        $set: action.payload.hearingDates
      }
    });
  case ACTIONS.HEARING_DATE_CHANGE:
    return update(state, {
      selectedHearingDate: {
        $set: action.payload.hearingDate
      }
    });
  default:
    return state;
  }
};

export default commonComponentsReducer;
