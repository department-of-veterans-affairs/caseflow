// usersSlice.js
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';
// import { fetchUsers } from 'yourApiFile'; // Import your API method

// Define the initial state
const initialState = {
  users: [],
  status: 'idle',
  error: null,
};

// Define the asynchronous thunk to fetch users
// TODO: Might be able to make this even more generic since a lot of the params are the same
// so the url/params might be the only thing that would change between all the various fetchUserThunks
export const fetchOrgUsersAsync = createAsyncThunk('users/fetchOrgUsers', async (businessLineUrl) => {
  // const response = await fetchUsers(businessLineUrl);
  // const response = await ApiUtil.get(`/users?organization=${businessLineUrl}`)
  const ORGANIZATION_USERS_URL = `/users?organization=${businessLineUrl}`;

  try {
    console.log(ORGANIZATION_USERS_URL);
    const response = await ApiUtil.get(ORGANIZATION_USERS_URL);

    console.log(response);
    const orgUserData = response.body.users.data.map(({ attributes, ...rest }) => ({ ...attributes, ...rest }));

    return orgUserData;

  } catch (error) {
    console.error(error);
    throw error;
  }
});

// Create the slice
const orgUserSlice = createSlice({
  name: 'users',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.
      addCase(fetchOrgUsersAsync.pending, (state) => {
        state.status = 'loading';
      }).
      addCase(fetchOrgUsersAsync.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.users = action.payload;
      }).
      addCase(fetchOrgUsersAsync.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message;
      });
  },
});

export default orgUserSlice.reducer;
