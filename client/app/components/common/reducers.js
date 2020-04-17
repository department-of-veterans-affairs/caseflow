import { ACTIONS } from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  dropdowns: {
    judges: {},
    hearingCoordinators: {},
    regionalOffices: {}
  },
  alerts: [],
  transitioningAlerts: {}
};

const dropdownsReducer = (state = {}, action = {}) => {
  switch (action.type) {
  case ACTIONS.FETCH_DROPDOWN_DATA:
    return update(state, {
      [action.payload.dropdownName]: {
        $set: {
          options: null,
          isFetching: true,
          errorMsg: null
        }
      }
    });
  case ACTIONS.RECEIVE_DROPDOWN_DATA:
    return update(state, {
      [action.payload.dropdownName]: {
        $set: {
          options: action.payload.data,
          isFetching: false,
          errorMsg: null
        }
      }
    });
  case ACTIONS.DROPDOWN_ERROR:
    return update(state, {
      [action.payload.dropdownName]: {
        errorMsg: {
          $set: action.payload.errorMsg
        }
      }
    });
  default:
    return state;
  }
};

const commonComponentsReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_ALERTS:
    return update(state, {
      alerts: {
        $set: [
          ...state.alerts,
          ...action.payload.alerts
        ]
      }
    });
  case ACTIONS.RECEIVE_TRANSITIONING_ALERT:
    return update(state, {
      alerts: {
        $set: [
          ...state.alerts,
          action.payload.alert
        ]
      },
      transitioningAlerts: {
        $set: {
          ...state.transitioningAlerts,
          [action.payload.key]: action.payload.alert
        }
      }
    });
  case ACTIONS.TRANSITION_ALERT:
    return update(state, {
      alerts: {
        $set: [
          ...state.alerts.filter((alert) => alert !== state.transitioningAlerts[action.payload.key]),
          state.transitioningAlerts[action.payload.key].next
        ]
      },
      transitioningAlerts: {
        $set: {
          ...state.transitioningAlerts,
          ...state.transitioningAlerts[action.payload.key] = state.transitioningAlerts[action.payload.key].next
        }
      }
    });
  case ACTIONS.REMOVE_ALERTS_WITH_EXPIRATION:
    return update(state, {
      alerts: {
        $set: state.alerts.filter((alert) => action.payload.timestamps.indexOf(alert.timestamp) === -1)
      }
    });
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
  case ACTIONS.FETCH_DROPDOWN_DATA:
  case ACTIONS.RECEIVE_DROPDOWN_DATA:
  case ACTIONS.DROPDOWN_ERROR:
    return update(state, {
      dropdowns: {
        $set: dropdownsReducer(state.dropdowns, action)
      }
    });
  default:
    return state;
  }
};

export default commonComponentsReducer;
