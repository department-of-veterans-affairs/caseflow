import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';
import ApiUtil from 'app/util/ApiUtil';
import { combineReducers } from 'redux';

export const submitMembershipRequestForm = createAsyncThunk('form/submit', async (formData) => {
  const response = await ApiUtil.
    post('/membership_requests', formData).
    catch((error) => {
      const errorMessage = error.response?.body?.errors?.at(0)?.detail || error.message;
      const customError = new Error(errorMessage);

      throw customError;
    });

  const { message, newMembershipRequests } = await response.body.data;

  return { message, newMembershipRequests };
});

export const initialState = {
  featureToggles: {},
  userOrganizations: [],
  organizationMembershipRequests: [],
  userLoggedIn: false,
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
    setUserLoggedIn: (state, action) => {
      state.userLoggedIn = action.payload;
    },
    setSuccessMessage: (state, action) => {
      state.messages.success = action.payload;
    },
    setErrorMessage: (state, action) => {
      state.messages.error = action.payload;
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
  setUserLoggedIn,
  setSuccessMessage,
  resetSuccessMessage,
  setErrorMessage,
  resetErrorMessage } = helpSlice.actions;

export const { resetFormSuccessMessage } = formSlice.actions;

export default helpReducers;
