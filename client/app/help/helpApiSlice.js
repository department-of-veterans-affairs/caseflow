import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';
import ApiUtil from 'app/util/ApiUtil';
import { combineReducers } from 'redux';

export const submitForm = createAsyncThunk('form/submit', async (formData) => {
  // TODO: Update this url to work with the form submission implementation
  const response = await ApiUtil.post('/help/submitOrganizationMembershipRequest', formData);
  const data = await response.json;

  if (response.status < 200 || response.status >= 300) {
    // TODO: Figure out how to handle errors for this.
    return 'It died do something';
  }

  return data;
});

export const initialState = {
  featureToggles: {},
  userOrganizations: [],
  organizationMembershipRequests: [],
};

const formSlice = createSlice({
  name: 'form',
  initialState: { formData: {}, status: 'idle', error: null },
  reducers: {},
  extraReducers: (builder) => {
    builder.
      addCase(submitForm.pending, (state) => {
        state.status = 'loading';
      }).
      addCase(submitForm.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.formData = action.payload;
      }).
      addCase(submitForm.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message;
      });
  },
});

const helpSlice = createSlice({
  name: 'help',
  initialState,
  reducers: {
    setFeatureToggles: (state, action) => {
      state.featureToggles = action.payload;
    },
    setUserOrganizations: (state, action) => {
      state.userOrganizations = action.payload;
    },
    setOrganizationMembershipRequests: (state, action) => {
      state.organizationMembershipRequests = action.payload;
    },
  },
});

const helpReducers = combineReducers({ help: helpSlice.reducer, form: formSlice.reducer });

export const { setFeatureToggles, setUserOrganizations, setOrganizationMembershipRequests } = helpSlice.actions;

export default helpReducers;
