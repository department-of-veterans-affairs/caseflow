import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  formData: {},
};

const addClaimantSlice = createSlice({
  name: 'editClaimant',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    editClaimantInformation: (state, action) => {
      const { formData } = action.payload;

      state.formData = {
        ...state.formData,
        ...formData,
      };
    },
  },
});

export const { cancel, editClaimantInformation } = addClaimantSlice.actions;

export default addClaimantSlice.reducer;
