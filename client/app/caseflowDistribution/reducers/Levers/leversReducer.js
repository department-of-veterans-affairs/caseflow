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
        changesOccurred: action.validChange,
        saveChangesActivated: !changesOccurred
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
  let formatted_lever_history = []
  const row_id_list = [...new Set(lever_history_list.map(x => `${x.created_at},${x.user}`))];

  row_id_list.forEach( function (row_id) {
    let row_created_at = row_id.split(',')[0];
    let row_user = row_id.split(',')[1];
    let row_items = lever_history_list.filter((lh_item) => lh_item.user == row_user && lh_item.created_at == row_created_at)

    formatted_lever_history.push(
      {
        created_at: row_items[0].created_at,
        user: row_items[0].user,
        titles: row_items.map((item) => item.title),
        original_values: row_items.map((item) => item.original_value),
        current_values: row_items.map((item) => item.current_value),
        units: row_items.map((item) => item.unit),
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
