import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from '../../util/ApiUtil';

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
      };
    },
  },
});

export const {
  cancel,
  editClaimantInformation
} = addClaimantSlice.actions;

export default addClaimantSlice.reducer;