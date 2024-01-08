import {ACTIONS } from '../levers/leversActionTypes';
import { update } from '../../../util/ReducerUtil';

export const initialState = {
  saveChangesActivated: false,
  editedLevers: [],
  levers: {},
  backendLevers: [],
  formattedHistory: {},
  historyList: {},
  changesOccurred: false,
  showSuccessBanner: false,
};

const leversReducer = (state = initialState, action = {}) => {
  switch (action.type) {

  case ACTIONS.INITIAL_LOAD:
    return update(state, {
      levers: {
        $set: action.payload.levers
      },
      backendLevers: {
        $set: action.payload.levers
      }
    });

  case ACTIONS.LOAD_LEVERS:
    return update(state, {
      levers: {
        $set: action.payload.levers
      }
    });
  // needs to be reworked; remove comment when done
  case ACTIONS.FORMAT_LEVER_HISTORY:
    return {
      ...state,
      historyList: formatLeverHistory(action.history)
    };

  // needs to be reworked; remove comment when done
  // we are no longer going to be replacing the backendLevers with levers on save. We will be replacing the list upon save with data from the backend
  case ACTIONS.SAVE_LEVERS:
    return {
      ...state,
      backendLevers: state.levers,
      saveChangesActivated: action.saveChangesActivated,
      changesOccurred: false
    };

  // needs to be reworked; remove comment when done
  case ACTIONS.REVERT_LEVERS:
    return {
      ...state,
      levers: state.backendLevers
    };

  // needs to be reworked; remove comment when done
  case ACTIONS.SHOW_SUCCESS_BANNER:
    return {
      ...state,
      showSuccessBanner: true
    };

  // needs to be reworked; remove comment when done
  case ACTIONS.HIDE_SUCCESS_BANNER:
    return {
      ...state,
      showSuccessBanner: false
    };

  default:
    return state;
  }
};

// this should probably be moved into the action in leversAction.js
export const formatLeverHistory = (lever_history_list) => {
  let formatted_lever_history = [];

  lever_history_list.forEach((lever_history_entry) => {

    formatted_lever_history.push(
      {
        user_name: lever_history_entry.user,
        created_at: lever_history_entry.created_at,
        lever_title: lever_history_entry.title,
        original_value: lever_history_entry.original_value,
        current_value: lever_history_entry.current_value
      }
    );
  });

  return formatted_lever_history;
};

// this should probably be moved into the action in leversAction.js
export const updateLevers = (current_levers, updated_lever, hasValueChanged) => {
  const leverIndex = current_levers.findIndex((lever) => lever.item == updated_lever.item);

  if (leverIndex !== -1) {

    const updatedLevers = [...current_levers];

    updatedLevers[leverIndex] = {
      ...updatedLevers[leverIndex],
      value: updated_lever.value,
      hasValueChanged
    };

    return updatedLevers;
  }

  return current_levers;
};

export default leversReducer;
