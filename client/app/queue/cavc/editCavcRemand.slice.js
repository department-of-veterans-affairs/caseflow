import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from 'app/util/ApiUtil';

const initialState = {
  step: 0,

  /**
   * This will hold substitution date, participantId, taskIds, etc
   */
  formData: {
    substitutionDate: null,
    participantId: null,
    closedTaskIds: [],
    openTaskIds: [],
    // ids to cancel when options are unchecked
    cancelledTaskIds: []
  },

  /**
   * This stores existing relationships, if present
   * This data is not usually part of appeal details due to performance
   */
  relationships: null,
  loadingRelationships: false,

  // Substitute's POA
  poa: null
};

const resetState = () => ({ ...initialState });

const editCavcRemandSlice = createSlice({
  name: 'edit_cavc_remand',
  initialState,
  reducers: {
    cancel: resetState,
    reset: resetState,
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

// Submit to the backend
export const completeEditCavcRemand = createAsyncThunk(
  'edit_cavc_remand/submit',
  async (data) => {
    try {
      const res = await ApiUtil.post(`/appeals/${data.source_appeal_id}/appellant_substitution`, { data });
      const attrs = res.body;

      return {
        substitution: attrs?.substitution,
        targetAppeal: attrs?.targetAppeal,
      };
    } catch (error) {
      console.error('Error when creating appellant substitution', error);
      throw error;
    }
  }
);

export const {
  cancel,
  reset,
  stepForward,
  stepBack,
  updateData,
} = editCavcRemandSlice.actions;

export default editCavcRemandSlice.reducer;
