import { createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../../util/ApiUtil';

export const completeDocketSwitchDenial = createAsyncThunk(
  'docketSwitch/deny',
  async (data) => {
    try {
      // Update this to conform to submission endpoint expectations
      const res = await ApiUtil.post('/docket_switches', { data });
      const result = res.body?.data;

      return result;
    } catch (error) {
      console.error('Error denying docket switch', error);
      throw error;
    }
  }
);
