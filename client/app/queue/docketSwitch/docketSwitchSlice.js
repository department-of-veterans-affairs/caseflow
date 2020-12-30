import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  step: 0,

  /**
   * This will hold receipt date, disposition, selected issue IDs, etc
   */
  formData: null,
};

const docketSwitchSlice = createSlice({
  name: 'docketSwitch',
  initialState,
  reducers: {
    stepForward: (state) => {
      console.log('stepForward');

      return { ...state, step: state.step + 1 };
    },
    stepBack: (state) => ({ ...state, step: state.step ? state.step - 1 : 0 }),
    updateDocketSwitch: (state, action) => {
      const updates = action.payload;

      state.formData = {
        ...state.formData,
        ...updates,
      };
    },
  },
});

export const {
  stepForward,
  stepBack,
  updateDocketSwitch,
} = docketSwitchSlice.actions;

export default docketSwitchSlice.reducer;
