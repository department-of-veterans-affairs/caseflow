import { createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../../util/ApiUtil';

export const createDocketSwitchRulingTask = createAsyncThunk(
  'tasks/createDocketSwitchRulingTask',
  async (data) => {
    try {
      const res = await ApiUtil.post('/tasks', { data });
      const updatedTasks = res.body?.tasks?.data;

      return updatedTasks;
    } catch (error) {
      console.error('Error creating task', error);
      throw error;
    }
  }
);
