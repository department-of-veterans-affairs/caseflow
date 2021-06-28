import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from 'app/util/ApiUtil';
import { formatRelationships } from 'app/intake/util';

export const fetchRelationships = createAsyncThunk(
  'substituteAppellant/fetchRelationships',
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

export const refreshAppellantPoa = createAsyncThunk(
  'substituteAppellant/refreshAppellantPoa',
  async ({ participantId }) => {
    try {
      const res = await ApiUtil.put(`/claimants/${participantId}/poa`);

      return res?.body?.poa;
    } catch (error) {
      console.error('Error fetching appellant poa', error);
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
    taskIds: [],
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

const substituteAppellantSlice = createSlice({
  name: 'substituteAppellant',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    reset: () => ({ ...initialState }),
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
    },
    [refreshAppellantPoa.fulfilled]: (state, action) => {
      state.poa = action.payload;
    },
    [refreshAppellantPoa.rejected]: (state, action) => {
      state.poa = null;
      console.error('To-do: let user know there was a problem', action);
    }
  },
});

// Submit to the backend
export const completeSubstituteAppellant = createAsyncThunk(
  'substituteAppellant/submit',
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
  stepForward,
  stepBack,
  updateData,
} = substituteAppellantSlice.actions;

export default substituteAppellantSlice.reducer;
