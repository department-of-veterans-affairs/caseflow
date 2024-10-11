import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  row: []
};

const savedSearchSlice = createSlice({
  name: 'savedSearch',
  initialState,
  reducers: {
    setSavedParams: (state, action) => {
      state.row = action.payload;
    }
  }
});

export default savedSearchSlice.reducer;
export const { setSavedParams } = savedSearchSlice.actions;
