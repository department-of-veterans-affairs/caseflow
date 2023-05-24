import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from 'app/util/ApiUtil';
import { formatRelationships } from 'app/intake/util';

export const fetchRelationships = createAsyncThunk(
  'editCavcRemand/fetchRelationships',
  async ({ appealId }) => {
    try {
      const res = await ApiUtil.get(`/appeals/${appealId}/veteran`, {
        query: { relationships: true },
      });

      return res?.body?.veteran?.relationships;
    } catch (error) {
      console.error('Error fetching relationships', error);
      throw error;
    }
  }
);

const initialState = {
  step: 0,

  /**
   * This will hold substitution date, participantId, taskIds, etc
   */
  formData: {
    substitutionDate: null,
    participantId: null,
    decisionType: null,
    docketNumber: null,
    judge: null,
    decisionDate: null,
    issueIds: null,
    federalCircuit: null,
    instructions: null,
    judgementDate: null,
    mandateDate: null,
    remandType: null,
    attorney: null,
    remandDatesProvided: null,
    remandAppealId: null,
    isAppellantSubstituted: null,
    // ids to reactivate tasks
    reActivateTaskIds: [],
    // ids to cancel when options are unchecked
    cancelTaskIds: []
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
  name: 'editCavcRemand',
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
  extraReducers: {
    [fetchRelationships.pending]: (state) => {
      state.loadingRelationships = true;
    },
    [fetchRelationships.fulfilled]: (state, action) => {
      state.relationships = action.payload ?
        formatRelationships(action.payload) :
        null;
      state.loadingRelationships = false;
    },
    [fetchRelationships.rejected]: (state) => {
      // In case of error, empty relationships array (will display message re no relationships found)
      state.relationships = null;
      state.loadingRelationships = false;
    }
  }
});

export const {
  cancel,
  reset,
  stepForward,
  stepBack,
  updateData,
} = editCavcRemandSlice.actions;

export default editCavcRemandSlice.reducer;
