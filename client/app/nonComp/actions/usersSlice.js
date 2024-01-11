import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';
import { find, get, has } from 'lodash';

// Define the initial state
const initialState = {
  users: [],
  status: 'idle',
  error: null,
};

/**
 * Asynchronous Redux Thunk for fetching user data based on different query parameters.
 *
 * @param {string} queryType - Specifies the type of query ('organization', 'css_id', 'role', etc.).
 * @param {Object} queryParams - Additional parameters for the query, e.g., { query, judgeID, excludeOrg }.
 *                 query - The data that is being used in the user query e.g. the org name or url
 *                   - organization - the query can be the Organization name or url
 *                   - role - [Attorney, Judge, HearingCoordinator, non_judges, non_dvcs]
 *                   - css_id - The CSS ID or name of users
 *                 optional params
 *                   judgeID - optional parameter that is the id of a judge that can be used during the
 *                             attorney role query. It returns only attorneys associated with that judge
 *                   excludeOrg - optional parameter that is the name or url of an organizatoin used during
 *                                the css_id query. It excludes users that are in that organization
 * @returns {Promise<Object>} A Promise that resolves with the fetched user data and analytics metadata,
 *                           or rejects with an error message and analytics information in case of failure.
 */
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

    return thunkApi.fulfillWithValue(preparedData, { analytics: true });

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
        state.users = action.payload;
      }).
      addCase(fetchUsers.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message;
      });
  },
});

export default usersSlice.reducer;
