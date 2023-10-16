import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';
import { find, get, has } from 'lodash';

// Define the initial state
const initialState = {
  users: [],
  status: 'idle',
  error: null,
};

// TODO: I need a better name for this. Maybe the whole slice too
// TODO: Also need some sort of comment to help display all the possible query values and the call structure
export const fetchUsers = createAsyncThunk('users/fetchUsers', async ({ queryType, queryParams }, thunkApi) => {
  let usersEndpoint = '/users';
  const { query, judgeID, excludeOrg } = queryParams;

  if (queryType === 'organization') {
    usersEndpoint = `${usersEndpoint}?organization=${query}`;
  } else if (queryType === 'css_id') {
    // This searches by user name and by css id but the query param is always called css_id
    usersEndpoint = `${usersEndpoint}?css_id=${query}`;
  } else if (queryType === 'role') {
    usersEndpoint = `${usersEndpoint}?role=${query}`;
  } else {
    // TODO: The meta tags don't work with our version of rtk
    return thunkApi.rejectWithValue('Invalid query type', { analytics: true });
  }

  // Optional get parameters that some of the controller actions use
  if (judgeID) {
    usersEndpoint = `${usersEndpoint}&judge_id=${judgeID}`;
  }

  if (excludeOrg) {
    usersEndpoint = `${usersEndpoint}&exclude_org=${excludeOrg}`;
  }

  try {
    const response = await ApiUtil.get(usersEndpoint);

    // Use the first key since the returning body can be a variety of different keys e.g. users, judges, attorneys
    const usersKey = Object.keys(response.body)[0];

    // Sometimes the key is .data and sometimes it's the toplevel object so try .data first and then the toplevel
    const possibleKeys = [`${usersKey}.data`, `${usersKey}`];
    const foundKeyPath = find(possibleKeys, (keyPath) => has(response.body, keyPath));
    const result = foundKeyPath ? get(response.body, foundKeyPath) : null;

    // Some of the data contains .attributes and some doesn't so expand all the attributes out to the top level objects
    const preparedData = result.map(({ attributes, ...rest }) => ({ ...attributes, ...rest }));
    const meta = { analytics: true };

    return { data: preparedData, meta };

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
