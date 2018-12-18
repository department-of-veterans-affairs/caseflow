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
  case ACTIONS.RECEIVE_HEARING_DAYS:
    return update(state, {
      hearingDays: {
        $set: action.payload.hearingDays
      }
    });
  case ACTIONS.HEARING_DAY_CHANGE:
    return update(state, {
      selectedHearingDay: {
        $set: action.payload.hearingDay
      }
    });
  case ACTIONS.HEARING_TIME_CHANGE:
    return update(state, {
      selectedHearingTime: {
        $set: action.payload.hearingTime
      }
    });
  default:
    return state;
  }
};

export default commonComponentsReducer;
