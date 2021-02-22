import { createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../../util/ApiUtil';

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
