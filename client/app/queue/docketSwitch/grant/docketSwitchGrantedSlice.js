import { createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../../util/ApiUtil';

export const completeDocketSwitchGranted = createAsyncThunk(
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
