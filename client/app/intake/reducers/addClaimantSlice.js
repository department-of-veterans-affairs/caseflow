import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  claimant: {},
  poa: {},
};

const addClaimantSlice = createSlice({
  name: 'addClaimant',
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
    clearClaimant: (state) => {
      state.claimant = {};
    },
    editPoaInformation: (state, action) => {
      const { formData } = action.payload;

      state.poa = {
        ...state.poa,
        ...formData,
      };
    },
    clearPoa: (state) => {
      state.poa = {};
    },
  },
});

export const {
  cancel,
  editClaimantInformation,
  clearClaimant,
  editPoaInformation,
  clearPoa,
} = addClaimantSlice.actions;

export default addClaimantSlice.reducer;
