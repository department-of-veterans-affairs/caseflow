import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  claimant: {},
  poa: {}
};

const addClaimantSlice = createSlice({
  name: 'editClaimant',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    editClaimantInformation: (state, action) => {
      const { formData } = action.payload;

      state.claimant = {
        ...state.claimant,
        ...formData,
      };
    },
  },
});

export const { cancel, editClaimantInformation } = addClaimantSlice.actions;

export default addClaimantSlice.reducer;
