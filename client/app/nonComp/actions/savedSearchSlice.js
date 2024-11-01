import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  selectedSearch: {},
  saveUserSearch: {}
};

const savedSearchSlice = createSlice({
  name: 'savedSearch',
  initialState,
  reducers: {
    selectSavedSearch: (state, action) => {
      state.selectedSearch = action.payload;
    },
    saveUserSearch: (state, action) => {
      state.saveUserSearch = action.payload;
    }
  }
});

export default savedSearchSlice.reducer;
export const { selectSavedSearch, saveUserSearch } = savedSearchSlice.actions;
