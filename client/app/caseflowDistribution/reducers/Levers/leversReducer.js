import {ACTIONS } from '../Levers/leversActionTypes';
import { update } from '../../../util/ReducerUtil';

export const initialState = {
  saveChangesActivated: false,
  loadedLevers: {},
  editedLevers: [],
  levers: [],
  initialLevers: [],
  formattedHistory: {},
  changesOccurred: false,
  showSuccessBanner: false,
};

const leversReducer = (state = initialState, action = {}) => {
  switch (action.type) {

  case ACTIONS.LOAD_LEVERS:
    return update(state, {
      loadedLevers: {
        $set: action.payload.loadedLevers
      }
    });

  // needs to be reworked; remove comment when done
  case ACTIONS.FORMAT_LEVER_HISTORY:
    return {
      ...state,
      formatted_history: formatLeverHistory(action.history)
    };


  // needs to be reworked; remove comment when done
  case ACTIONS.SAVE_LEVERS:
    return {
      ...state,
      initial_levers: state.levers,
      saveChangesActivated: action.saveChangesActivated,
      changesOccurred: false
    };

  // needs to be reworked; remove comment when done
  case ACTIONS.REVERT_LEVERS:
    return {
      ...state,
      levers: state.initial_levers
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
  console.log(lever_history_list);
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
