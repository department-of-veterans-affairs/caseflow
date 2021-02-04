import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from '../../util/ApiUtil';

const initialState = {
  step: 0,

  /**
   * This will hold receipt date, disposition, selected issue IDs, etc
   */
  formData: {},
};

const addClaimantPoaSlice = createSlice({
  name: 'addClaimantPoa',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    // stepForward: (state) => ({ ...state, step: state.step + 1 }),
    // stepBack: (state) => ({ ...state, step: state.step ? state.step - 1 : 0 }),
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
} = addClaimantPoaSlice.actions;

export default addClaimantPoaSlice.reducer;