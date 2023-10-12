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
export const fetchOrgUsers = createAsyncThunk('users/fetchOrgUsers', async (organizationUrlorName) => {
  const ORGANIZATION_USERS_URL = `/users?organization=${organizationUrlorName}`;

  // TOOD: Does this need try catch? or is it already a promise that has pass/fail
  try {
    const response = await ApiUtil.get(ORGANIZATION_USERS_URL);
    const orgUserData = response.body.users.data.map(({ attributes, ...rest }) => ({ ...attributes, ...rest }));

    return orgUserData;

  } catch (error) {
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
        state.users = action.payload;
      }).
      addCase(fetchOrgUsers.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message;
      });
  },
});

export default orgUserSlice.reducer;
