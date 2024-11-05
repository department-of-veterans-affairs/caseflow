import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';

const initialState = {
  status: 'idle',
  error: null,
  message: null,
  selectedSearch: {},
  saveUserSearch: {}
};

export const createSearch = createAsyncThunk(
  'posts/createSearch',
  async({ organizationUrl, postData }, thunkApi) => {
    try {
      const url = `/decision_reviews/${organizationUrl}/searches`;
      const response = await ApiUtil.post(url, { data: postData });

      return thunkApi.fulfillWithValue(response.body);
    } catch (error) {
      console.error(error);

      return thunkApi.rejectWithValue(`Save search creation failed: ${error.message}`, { analytics: true });
    }
  });

const savedSearchSlice = createSlice({
  name: 'savedSearch',
  initialState,
  reducers: {
    selectSavedSearch: (state, action) => {
      state.selectedSearch = action.payload;
    },
    saveUserSearch: (state, action) => {
      state.saveUserSearch = action.payload;
    }
  },
  extraReducers: (builder) => {
    builder.
      addCase(createSearch.pending, (state) => {
        state.status = 'loading';
      }).
      addCase(createSearch.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.message = action.payload.message;
      }).
      addCase(createSearch.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message;
      });
  },
});

export default savedSearchSlice.reducer;
export const { selectSavedSearch, saveUserSearch } = savedSearchSlice.actions;
