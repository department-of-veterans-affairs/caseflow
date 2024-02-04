import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';
import { getMinutesToMilliseconds } from '../../util/DateUtil';

// Define the initial state
const initialState = {
  // We might not keep filters here and may only persist them in local state
  status: 'idle',
  error: null,
  events: [],
  getIndividiualHistory: {
    status: 'idle',
    error: null,
  }
};

export const downloadReportCSV = createAsyncThunk('changeHistory/downloadReport',
  async ({ organizationUrl, filterData }, thunkApi) => {
    try {
      const postData = ApiUtil.convertToSnakeCase(filterData);
      const getOptions = {
        query: postData.filters,
        headers: { Accept: 'text/csv' },
        responseType: 'arraybuffer',
        timeout: { response: getMinutesToMilliseconds(3) }
      };
      const response = await ApiUtil.get(`/decision_reviews/${organizationUrl}/report`, getOptions);

      // Create a Blob from the array buffer
      const blob = new Blob([response.body], { type: 'text/csv' });

      // Access the filename from the response headers
      const contentDisposition = response.headers['content-disposition'];
      const matches = contentDisposition.match(/filename="(.+)"/);

      const filename = matches ? matches[1] : 'report.csv';

      // Create a download link to trigger the download of the csv
      const link = document.createElement('a');

      link.href = window.URL.createObjectURL(blob);
      link.download = filename;

      // Append the link to the document, trigger a click on the link, and remove the link from the document
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      return thunkApi.fulfillWithValue('success', { analytics: true });

    } catch (error) {
      console.error(error);

      return thunkApi.rejectWithValue(`CSV generation failed: ${error.message}`, { analytics: true });
    }
  });

export const getIndividiualHistory = createAsyncThunk(
  'changeHistory/individualReport',
  async ({ organizationUrl, taskId }, thunkApi) => {
    try {
      const url = `/decision_reviews/${organizationUrl}/tasks/${taskId}/history`;

      const response = await ApiUtil.get(url);

      console.log(response.body);

      return thunkApi.fulfillWithValue(response.body);

    } catch (error) {
      console.error(error);

      return thunkApi.rejectWithValue(`Individual Report Failed: ${error.message}`, { analytics: true });
    }
  });

const changeHistorySlice = createSlice({
  name: 'changeHistory',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.
      addCase(getIndividiualHistory.pending, (state) => {
        state.getIndividiualHistory.status = 'loading';
      }).
      addCase(getIndividiualHistory.fulfilled, (state, action) => {
        state.getIndividiualHistory.status = 'succeeded';
        state.events = action.payload;
      }).
      addCase(getIndividiualHistory.rejected, (state, action) => {
        state.getIndividiualHistory.status = 'failed';
        state.error = action.error.message;
      }).
      addCase(downloadReportCSV.pending, (state) => {
        state.status = 'loading';
      }).
      addCase(downloadReportCSV.fulfilled, (state) => {
        state.status = 'succeeded';
      }).
      addCase(downloadReportCSV.rejected, (state, action) => {
        state.status = 'failed';
        state.error = action.error.message;
      });
  },
});

export default changeHistorySlice.reducer;
