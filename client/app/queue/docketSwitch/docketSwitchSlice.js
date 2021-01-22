import { createSlice } from '@reduxjs/toolkit';
import { ACTIONS } from '../constants';
import { createAsyncThunk } from '@reduxjs/toolkit';
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
   issueIds: []
  },
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

      const { formData: updates } = action.payload;
      updates.receiptDate = updates.receiptDate?.toISOString() ?? undefined; 
      
      state.formData = {
        ...state.formData,
        ...updates,
      };
    }
  },
});


const completeDocketSwitchGranted = createAsyncThunk(
  'docketSwitch/grant',
  async (data) => {
    try {
      // Update this to conform to submission endpoint expectations
      const res = await ApiUtil.post('/docket_switches', { data });
      const result = res.body?.data;

      return result;
    } catch (error) {
      console.error('Error granting docket switch', error);
      throw error;
    }
  }
);

export const {
  stepForward,
  stepBack,
  updateDocketSwitch
} = docketSwitchSlice.actions;

export default docketSwitchSlice.reducer;
