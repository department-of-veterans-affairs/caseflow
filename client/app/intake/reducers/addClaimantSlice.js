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
    editPoaInformation: (state, action) => {
      const { formData } = action.payload;

      state.poa = {
        ...state.poa,
        ...formData,
      };
    },
  },
});

export const { cancel, editClaimantInformation, editPoaInformation } = addClaimantSlice.actions;

export default addClaimantSlice.reducer;
