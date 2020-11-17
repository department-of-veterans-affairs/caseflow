import { createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../../util/ApiUtil';

export const createDocketSwitchGrantedTask = createAsyncThunk(
  'tasks/createDocketSwitchGrantedTask',
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

export const createDocketSwitchDeniedTask = createAsyncThunk(
  'tasks/createDocketSwitchDeniedTask',
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
