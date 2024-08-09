// External Dependencies
import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';

// Local Dependencies
import ApiUtil from 'app/util/ApiUtil';
import { ENDPOINT_NAMES } from './constants/reader';

/**
 * Case Select Initial State
 */
export const initialState = {
  selected: {},
  loadFailed: false,
};

/**
 * Appeal Details State
 */
export const fetchAppealDetails = createAsyncThunk('appeal/fetch', async (vacolsId) => {
  // Request the Appeal
  const { body } = await ApiUtil.get(`/reader/appeal/${vacolsId}?json`, {}, ENDPOINT_NAMES.APPEAL_DETAILS);

  // Return the Body containing the appeal details
  return { ...body, vacolsId };
});

/**
 * Case Select Combined Reducer/Action creators
 */
const appealSlice = createSlice({
  name: 'appeal',
  initialState,
  reducers: {
  },
  extraReducers: (builder) => {
    builder.
      addCase(fetchAppealDetails.fulfilled, (state, action) => {
        state.selected = {
          ...action.payload.appeal.data.attributes,
          id: action.payload.vacolsId
        };
      }).
      addCase(fetchAppealDetails.rejected, (state) => {
        state.loadFailed = true;
      });
  }
});

// Export the Reducer actions
// export const {
// } = appealSlice.actions;

// Default export the reducer
export default appealSlice.reducer;
