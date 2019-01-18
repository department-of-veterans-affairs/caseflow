import { ACTIONS } from './constants';
import { update } from '../../../util/ReducerUtil';

export const initialState = {
  judges: {},
  hearingCoordinators: {},
  regionalOffices: {}
};

const hearingDropdownDataReducer = (state = initialState, action = {}) => {
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

export default hearingDropdownDataReducer;
