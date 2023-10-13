import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';

// Define the initial state
const initialState = {
  users: [],
  status: 'idle',
  error: null,
};

// TODO: Might be able to make this even more generic since a lot of the params are the same
// so the url/params might be the only thing that would change between all the various fetchUserThunks
// TOOD: Figure out how to set meta: analytics for async thunks, if it's even possible
export const fetchOrgUsers = createAsyncThunk('users/fetchOrgUsers', async (organizationUrlOrName) => {
  const ORGANIZATION_USERS_URL = `/users?organization=${organizationUrlOrName}`;

  try {
    const response = await ApiUtil.get(ORGANIZATION_USERS_URL);
    const orgUserData = response.body.users.data.map(({ attributes, ...rest }) => ({ ...attributes, ...rest }));

    const meta = { analytics: true };
    // return { data: orgUserData, meta: { analytics: true } };
    // return { orgUserData, meta: { analytics: true } };

    // return {orgUserData}
    // return orgUserData;

    // return thunkApi.fulfillWithValue(orgUserData);
    return { data: orgUserData, meta };

  } catch (error) {
    // TODO: Should this be a rejectWithValue??
    // Otherwise why even have a try catch since it would throw and error no matter what
    // The only thing this does differently is a console log
    console.error(error);
    throw error;
  }
});

const orgUserSlice = createSlice({
  name: 'users',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.
      addCase(fetchOrgUsers.pending, (state) => {
        state.status = 'loading';
      }).
      addCase(fetchOrgUsers.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.users = action.payload.data;
      }).
      addCase(fetchOrgUsers.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message;
      });
  },
});

export default orgUserSlice.reducer;
