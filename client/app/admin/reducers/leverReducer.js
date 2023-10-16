// Define initial state
const initialState = {
  levers: [
    // Your lever objects here
  ],
  activeLevers: ['lever2', 'lever1'], // Example order of active levers
};
​
// Define reducer
const leverReducer = (state = initialState, action) => {
  // Handle actions to update the state
  switch (action.type) {
    case 'REORDER_LEVERS':
      return {
        ...state,
        activeLevers: action.newOrder,
      };
    case 'UPDATE_LEVER_VALUE':
      // Find the lever by item and update the new value
      const updatedLevers = state.levers.map((lever) => {
        if (lever.item === action.item) {
          return {
            ...lever,
            newValue: action.newValue,
          };
        }
        return lever;
      });
​
      return {
        ...state,
        levers: updatedLevers,
      };
    default:
      return state;
  }
};
​// add the history function
export default leverReducer;