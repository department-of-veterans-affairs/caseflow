import { ACTIONS } from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  dropdowns: {
    judges: {},
    hearingCoordinators: {},
    regionalOffices: {}
  },
  forms: {}
};

const dropdownsReducer = (state = {}, action = {}) => {
  switch (action.type) {
  case ACTIONS.FETCH_DROPDOWN_DATA:
    return update(state, {
      [action.payload.dropdownName]: {
        $set: {
          options: null,
          isFetching: true
        }
      }
    });
  case ACTIONS.RECEIVE_DROPDOWN_DATA:
    return update(state, {
      [action.payload.dropdownName]: {
        $set: {
          options: action.payload.data,
          isFetching: false
        }
      }
    });
  default:
    return state;
  }
};

const formsReducer = (state = {}, action = {}) => {
  const formState = state[action.payload.formName] || {};

  switch (action.type) {
  case ACTIONS.CHANGE_FORM_DATA:
    return update(state, {
      [action.payload.formName]: {
        $set: {
          ...formState,
          ...action.payload.formData
        }
      }
    });
  default:
    return state;
  }
};

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
  case ACTIONS.FETCH_DROPDOWN_DATA:
  case ACTIONS.RECEIVE_DROPDOWN_DATA:
    return update(state, {
      dropdowns: {
        $set: dropdownsReducer(state.dropdowns, action)
      }
    });
  case ACTIONS.CHANGE_FORM_DATA:
    return update(state, {
      forms: {
        $set: formsReducer(state.forms, action)
      }
    });
  default:
    return state;
  }
};

export default commonComponentsReducer;
