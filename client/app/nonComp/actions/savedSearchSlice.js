import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';

const initialState = {
  selectedSearch: {},
  fetchedSearches: {
    error: null,
    status: 'idle',
    searches: {},
    userSearches: {}
  }
};

export const fetchedSearches = createAsyncThunk(
  'savedSearch',
  async ({ organizationUrl }, thunkApi) => {
    try {
      const url = `/decision_reviews/${organizationUrl}/searches.json`;

      const response = await ApiUtil.get(url);

      const searches = response.body;

      const flattenSearchesData = {
        allSearches: searches.all_searches.map(({ attributes, ...rest }) => ({ ...attributes, ...rest })),
        userSearches: searches.user_searches.map(({ attributes, ...rest }) => ({ ...attributes, ...rest }))
      };

      return thunkApi.fulfillWithValue(flattenSearchesData);

    } catch (error) {
      console.error(error);

      return thunkApi.rejectWithValue(`Individual Report Failed: ${error.message}`, { analytics: true });
    }
  });

const savedSearchSlice = createSlice({
  name: 'savedSearch',
  initialState,
  reducers: {
    selectSavedSearch: (state, action) => {
      state.selectedSearch = action.payload;
    }
  },
  extraReducers: (builder) => {
    builder.
      addCase(fetchedSearches.pending, (state) => {
        state.fetchedSearches.status = 'loading';
      }).
      addCase(fetchedSearches.fulfilled, (state, action) => {
        state.fetchedSearches.status = 'succeeded';
        state.fetchedSearches.searches = action.payload.allSearches;
        state.fetchedSearches.userSearches = action.payload.userSearches;
      }).
      addCase(fetchedSearches.rejected, (state, action) => {
        state.fetchedSearches.status = 'failed';
        state.error = action.error.message;
      });
  },
});

export default savedSearchSlice.reducer;
export const { selectSavedSearch } = savedSearchSlice.actions;
