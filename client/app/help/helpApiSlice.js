import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';
import ApiUtil from 'app/util/ApiUtil';
import { combineReducers } from 'redux';

export const submitMembershipRequestForm = createAsyncThunk('form/submit', async (formData) => {
  // TODO: Format the formData into a data object for json here instead of over in VhaMembershipRequestForm
  const response = await ApiUtil.post('/membership_requests', formData);
  // const data = await response.body;
  const { message, newMembershipRequests } = await response.body.data;

  // JSON.parse(response)
  // console.log(response.body.data);

  console.log(message);
  console.log(newMembershipRequests);

  // console.log(response);
  // console.log(response.status);

  // console.log(data);
  // alert(message);
  // dispatch();

  if (response.status < 200 || response.status >= 300) {
    // TODO: Figure out how to handle server errors?
    // Those might not be caught by the normal thunk reject error handling.
    return 'It died do something';
  }

  return { message, newMembershipRequests };
  // return 'duh';
});

export const initialState = {
  featureToggles: {},
  userOrganizations: [],
  organizationMembershipRequests: [],
  messages: {
    success: null,
    error: null
  },
};

const formSlice = createSlice({
  name: 'form',
  initialState: { message: null, status: 'idle', error: null, requestedOrgNames: [] },
  reducers: {
    resetFormSuccessMessage: (state) => {
      state.message = null;
    },
  },
  extraReducers: (builder) => {
    builder.
      addCase(submitMembershipRequestForm.pending, (state) => {
        state.status = 'loading';
      }).
      addCase(submitMembershipRequestForm.fulfilled, (state, action) => {
        state.status = 'succeeded';
        state.message = action.payload.message;
        // state.requestedOrgNames = action.payload.requestedOrgNames;
      }).
      addCase(submitMembershipRequestForm.rejected, (state, action) => {
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
    // TODO: Might rename these two setMessages to showMessages to more line up with how the queue ui redux store works.
    setSuccessMessage: (state, action) => {
      state.messages.success = action.payload;
    },
    setErrorMessage: (state, action) => {
      state.messsages.error = action.payload;
    },
    resetSuccessMessage: (state) => {
      state.messages.success = null;
    },
    resetErrorMessage: (state) => {
      state.messages.error = null;
    }
  },
});

const helpReducers = combineReducers({ help: helpSlice.reducer, form: formSlice.reducer });

export const { setFeatureToggles,
  setUserOrganizations,
  setOrganizationMembershipRequests,
  setSuccessMessage } = helpSlice.actions;

export const { resetFormSuccessMessage } = formSlice.actions;

export default helpReducers;
