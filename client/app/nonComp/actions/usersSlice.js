import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';

// Define the initial state
const initialState = {
  users: [],
  status: 'idle',
  error: null,
};

// TODO: I need a better name for this. Maybe the whole slice too
export const fetchUsers = createAsyncThunk('users/fetchUsers', async ({ queryType, queryParam }, thunkApi) => {
  let usersEndpoint = '/users';

  if (queryType === 'organization') {
    usersEndpoint = `${usersEndpoint}?organization=${queryParam}`;
  } else if (queryType === 'cssID') {
    // This searches by user name and by css id but the query param is always called css_id
    usersEndpoint = `${usersEndpoint}?css_id=${queryParam}`;
  } else if (queryType === 'role') {
    usersEndpoint = `${usersEndpoint}?role=${queryParam}`;
  } else {
    // TODO: The meta tags don't work with our version of rtk
    return thunkApi.rejectWithValue('Invalid query type', { analytics: true });
  }

  try {
    const response = await ApiUtil.get(usersEndpoint);

    // Use the first key since the returning body can be a variety of different keys e.g. users, judges, attorneys
    const usersKey = Object.keys(response.body)[0];
    const preparedUsers = response.body[usersKey].map(({ attributes, ...rest }) => ({ ...attributes, ...rest }));
    const meta = { analytics: true };

    return { data: preparedUsers, meta };

  } catch (error) {
    console.error(error);

    return thunkApi.rejectWithValue('Users API request failed', { analytics: true });
  }
}
);

const usersSlice = createSlice({
  name: 'users',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.
      addCase(fetchUsers.pending, (state) => {
        state.status = 'loading';
      }).
      addCase(fetchUsers.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.users = action.payload.data;
      }).
      addCase(fetchUsers.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message;
      });
  },
});

export default usersSlice.reducer;
