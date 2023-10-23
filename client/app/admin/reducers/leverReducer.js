import { uniq } from 'lodash';
import { createSlice } from '@reduxjs/toolkit';

export const initialState = {
  initialLevers: [],
  currentLevers: [],
  leverHistory: []
}

const leverSlicer = initState => createSlice({
  name: 'leverReducer',
  initState,
  reducers: {
    displayLeverHistory: (state, action) => {
      state.leverHistory = formatLeverHistory(action.payload)
    },
    updateLeverValue: (state, action) => {
      state.currentLevers = updateLevers(state.currentLevers, action.payload)
    },
    saveLevers: (state, action) => {
      return state.currentLevers
    },
    revertLevers: (state, action) => {
      return state.initialLevers
    }
  }
});

export const formatLeverHistory = (lever_history_list) => {
  let formatted_lever_history = []
  const row_id_list = _.uniq(lever_history_list.map(x => `${x.created_at},${x.user}`)); //get unique created_at + user

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
  leverIndex = current_levers.findIndex((lever => lever.item == updated_lever.item));
  current_levers[leverIndex].value = updated_lever.value;

  return current_levers
};

const generateLeverSlicer = initState => {
  return leverSlicer(initState).reducer;
};

export const leverReducer = leverSlicer(initialState);

// Export the Reducer actions
export const {
  displayLeverHistory,
  updateLeverValue, //trigger when user makes a change
  saveLevers, //return data for the row in the DB (save button is pressed)
  revertLevers // cancel button is pressed
} = leverReducer.actions;

export default generateLeverSlicer;
