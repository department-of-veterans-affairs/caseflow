import * as Constants from './leversActionTypes';

export const initialState = {
  saveChangesActivated: false,
  levers: [],
  initial_levers: [],
  formatted_history: {},
  changesOccurred: false
};

const leversReducer = (state = initialState, action = {}) => {
  switch (action.type) {
    case Constants.FORMAT_LEVER_HISTORY:
      return {
        ...state,
        formatted_history: formatLeverHistory(action.history)
      }
    case Constants.UPDATE_LEVER_VALUE:
      const updatedLevers = updateLevers(state.levers, action.updated_lever);
      const changesOccurred = JSON.stringify(updatedLevers) !== JSON.stringify(state.initial_levers)
      return {
        ...state,
        levers: updatedLevers,
        changesOccurred,
      }
    case Constants.SAVE_LEVERS:
      return {
        ...state,
        initial_levers: state.levers,
        saveChangesActivated: action.saveChangesActivated,
        changesOccurred: false
      }
    case Constants.REVERT_LEVERS:
      return {
        ...state,
        levers: state.initial_levers
      }
    default:
      return state
  }
}

export const formatLeverHistory = (lever_history_list) => {
  console.log(lever_history_list)
  let formatted_lever_history = []

  lever_history_list.forEach( function (lever_history_entry) {

    formatted_lever_history.push(
      {
        user_name: lever_history_entry.user,
        created_at: lever_history_entry.created_at,
        lever_title: lever_history_entry.title,
        original_value: lever_history_entry.original_value,
        current_value: lever_history_entry.current_value
      }
    )
  });

  return formatted_lever_history;
};

export const updateLevers = (current_levers, updated_lever) => {
  const leverIndex = current_levers.findIndex((lever => lever.item == updated_lever.item));

  if (leverIndex !== -1) {

    const updatedLevers = [...current_levers];

    updatedLevers[leverIndex] = {
      ...updatedLevers[leverIndex],
      value: updated_lever.value,
    };

    return updatedLevers
  }

  return current_levers
};

export default leversReducer;
