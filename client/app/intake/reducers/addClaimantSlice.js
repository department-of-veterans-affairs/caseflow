import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from '../../util/ApiUtil';

const initialState = {
  formData: {},
};

const addClaimantSlice = createSlice({
  name: 'addClaimantPoa',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    addClaimant: (state, action) => {
      const { formData } = action.payload;

      state.formData = {
        ...state.formData,
      };
    },
  },
});

export const {
  cancel,
  addClaimant
} = addClaimantSlice.actions;

export default addClaimantSlice.reducer;