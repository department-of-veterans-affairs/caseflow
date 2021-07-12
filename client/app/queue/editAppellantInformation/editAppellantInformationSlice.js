import { createSlice } from '@reduxjs/toolkit';
import { mapAppellantDataToApi } from './utils';

const initialState = {
  claimant: {},
};

const editClaimantSlice = createSlice({
  name: 'editClaimant',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    updateAppellantInformation: (_state, action) => {
      const { formData, _id } = action.payload;
      
      // CASEFLOW-1923: Update the map function here to properly map the form data for the API
      const _appellantPayload = mapAppellantDataToApi(formData);

      // CASEFLOW-1923: Make API call to update claimant information using the appellantPayload
    },
    clearClaimant: (state) => {
      state.claimant = {};
    },
  },
});

export const {
  cancel,
  updateAppellantInformation,
  clearClaimant,
} = editClaimantSlice.actions;

export default editClaimantSlice.reducer;
