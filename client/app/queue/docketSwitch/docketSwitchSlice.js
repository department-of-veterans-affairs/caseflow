import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from '../../util/ApiUtil';
import { onReceiveAmaTasks } from '../QueueActions';

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

      state.formData = {
        ...state.formData,
        ...updates,
        newTasks: updates?.newTasks
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

export const createDocketSwitchRulingTask = createAsyncThunk(
  'tasks/createDocketSwitchRulingTask',
  async (data) => {
    try {
      const res = await ApiUtil.post('/tasks', { data });
      const updatedTasks = res.body?.tasks?.data;
      debugger
      return updatedTasks;
    } catch (error) {
      console.error('Error creating task', error);
      throw error;
    }
  }
);

export const addressDocketSwitchRuling = createAsyncThunk(
  'tasks/addressDocketSwitchRuling',
  async (data) => {
    try {
      const res = await ApiUtil.post('/docket_switches/address_ruling', { data });

      return res.body;
    } catch (error) {
      console.error('Error creating task', error);
      throw error;
    }
  }
);

// This should likely move to a more generic task slice when it exists
export const completeTask = createAsyncThunk(
  'tasks/complete',
  async ({ taskId }, { dispatch }) => {
    try {
      const res = await ApiUtil.patch(`/tasks/${taskId}`, {
        data: { task: { status: 'completed' } },
      });
      const updatedTasks = res.body?.tasks?.data;

      dispatch(onReceiveAmaTasks(updatedTasks));

      return updatedTasks;
    } catch (error) {
      console.error('Error creating task', error);
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
