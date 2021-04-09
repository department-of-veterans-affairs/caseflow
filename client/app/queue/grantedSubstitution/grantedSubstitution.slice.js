import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from '../../util/ApiUtil';
import { onReceiveAmaTasks } from '../QueueActions';

const initialState = {
  step: 0,

  /**
   * This will hold substitution date, participantId, etc
   */
  formData: {
    substitutionDate: null,
    participantId: null,
  },
};

const grantedSubstitutionSlice = createSlice({
  name: 'substituteAppellant',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    stepForward: (state) => ({ ...state, step: state.step + 1 }),
    stepBack: (state) => ({ ...state, step: state.step ? state.step - 1 : 0 }),
    updateData: (state, action) => {
      const { formData: updates } = action.payload;

      state.formData = {
        ...state.formData,
        ...updates,
        newTasks: updates?.newTasks,
      };
    },
  },
});

// We can likely use a variant of this to submit to the backend
// (need more info on what we are saving and what is being returned)
export const completeDocketSwitchGranted = createAsyncThunk(
  'grantedSubstitution/submit',
  async (data) => {
    try {
      const res = await ApiUtil.post('/appellant_substitutions', { data });
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
  updateData,
} = grantedSubstitutionSlice.actions;

export default grantedSubstitutionSlice.reducer;
