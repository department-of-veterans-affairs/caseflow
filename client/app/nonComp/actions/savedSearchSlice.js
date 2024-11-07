import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';

const initialState = {
  status: 'idle',
  error: null,
  message: null,
  selectedSearch: {},
  fetchedSearches: {
    error: null,
    status: 'idle',
    searches: [],
    userSearches: []
  },
  saveUserSearch: {}
};

export const createSearch = createAsyncThunk(
  'posts/createSearch',
  async({ organizationUrl, postData }, thunkApi) => {
    try {
      const url = `/decision_reviews/${organizationUrl}/searches`;
      const response = await ApiUtil.post(url, { data: ApiUtil.convertToSnakeCase(postData) });

      return thunkApi.fulfillWithValue(response.body);
    } catch (error) {
      console.error(error);

      return thunkApi.rejectWithValue(`Save search creation failed: ${error.message}`, { analytics: true });
    }
  });

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
    },
    saveUserSearch: (state, action) => {
      state.saveUserSearch = action.payload;
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
      }).
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
