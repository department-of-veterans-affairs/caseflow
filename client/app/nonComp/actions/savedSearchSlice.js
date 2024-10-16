import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  selectedSearch: {}
};

const savedSearchSlice = createSlice({
  name: 'savedSearch',
  initialState,
  reducers: {
    selectSavedSearch: (state, action) => {
      state.selectedSearch = action.payload;
    }
  }
});

export default savedSearchSlice.reducer;
export const { selectSavedSearch } = savedSearchSlice.actions;
