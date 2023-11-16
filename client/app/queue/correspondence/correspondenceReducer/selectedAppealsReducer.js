import { ACTIONS } from './correspondenceConstants';
import { update } from 'app/util/ReducerUtil';

export const initialState = {
  selectedAppeals: []
};

export const selectedAppealsReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.SAVE_APPEAL_CHECKBOX_STATE:
    if (action.payload.isChecked) {
      return update(state, {
        selectedAppeals: {
          $push: [action.payload.id]
        }
      });
    }

    return update(state, {
      selectedAppeals: {
        $set: state.selectedAppeals.filter((id) => id !== action.payload.id)
      }
    });
  case ACTIONS.CLEAR_APPEAL_CHECKBOX_STATE:
    return update(state, {
      selectedAppeals: {
        $set: []
      }
    });
  default:
    return state;
  }
};

export default selectedAppealsReducer;
