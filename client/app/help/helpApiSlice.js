import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';
import ApiUtil from 'app/util/ApiUtil';

export const submitForm = createAsyncThunk('form/sbumit', async (formData) => {
  // TODO: Update this url to work with the form submission implementation
  const response = await ApiUtil.post('/help/submitOrganizationMembershipRequest', formData);
  const data = await response.json;

  if (response.status < 200 || response.status >= 300) {
    // TODO: Figure out how to handle errors for this.
    return 'It died do something';
  }

  return data;
});

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

export default formSlice.reducer;
