import { createSlice } from '@reduxjs/toolkit';

/**
 * PDF Initial State
 */
export const initialState = {
  crumbs: [

  ]
};

/**
 * PDF Combined Reducer/Action creators
 */
const routeSlice = createSlice({
  name: 'routes',
  initialState,
  reducers: {
    navigate: {
      reducer: (state, action) => {
        state.crumbs = action.payload.crumbs;
      }
    },
  }
});

// Export the Reducer actions
export const {
  navigate
} = routeSlice.actions;

// Default export the reducer
export default routeSlice.reducer;
