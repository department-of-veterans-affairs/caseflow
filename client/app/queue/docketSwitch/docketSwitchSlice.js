import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from '../../util/ApiUtil';

const initialState = {
  step: 0,

  /**
   * This will hold receipt date, disposition, selected issue IDs, etc
   */
  formData: {
    disposition: null,
    receiptDate: null,
    docketType: null,
    issueIds: [],
    newTasks: [],
  },
};

const docketSwitchSlice = createSlice({
  name: 'docketSwitch',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    stepForward: (state) => ({ ...state, step: state.step + 1 }),
    stepBack: (state) => ({ ...state, step: state.step ? state.step - 1 : 0 }),
    updateDocketSwitch: (state, action) => {
      const { formData: updates } = action.payload;

      if (updates.receiptDate) {
        updates.receiptDate = updates.receiptDate?.toISOString();
      }

      state.formData = {
        ...state.formData,
        ...updates,
      };
    },
  },
});

export const completeDocketSwitchGranted = createAsyncThunk(
  'docketSwitch/grant',
  async (data) => {
    try {
      const res = await ApiUtil.post('/docket_switches', { data });
      const attrs = res.body?.data?.attributes;

      return {
        oldAppealId: attrs?.old_appeal_uuid,
        newAppealId: attrs?.new_appeal_uuid,
      };
    } catch (error) {
      console.error('Error granting docket switch', error);
      throw error;
    }
  }
);

export const {
  cancel,
  stepForward,
  stepBack,
  updateDocketSwitch,
} = docketSwitchSlice.actions;

export default docketSwitchSlice.reducer;
