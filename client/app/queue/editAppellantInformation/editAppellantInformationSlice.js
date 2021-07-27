import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  claimant: {},
};

const editClaimantSlice = createSlice({
  name: 'editClaimant',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    clearClaimant: (state) => {
      state.claimant = {};
    },
  },
});

export const {
  cancel,
  clearClaimant,
} = editClaimantSlice.actions;

export default editClaimantSlice.reducer;
