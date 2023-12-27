import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';

// Define the initial state
const initialState = {
  // We might not keep filters here and may only persist them in local state
  filters: [],
  events: [],
  downloadReportCSV: {
    status: 'idle',
    error: null,
  },
  fetchClaimEvents: {
    status: 'idle',
    error: null,
  },
  status: 'idle',
  error: null,
};

export const downloadReportCSV = createAsyncThunk('changeHistory/downloadReport',
  async ({ organizationUrl, filterData }, thunkApi) => {
    try {
      const postData = ApiUtil.convertToSnakeCase(filterData);
      const getOptions = { query: postData.filters, headers: { Accept: 'text/csv' }, responseType: 'arraybuffer' };
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

export const fetchClaimEvents = createAsyncThunk('changeHistory/fetchClaimEvents',
  async ({ taskID, businessLineUrl }, thunkApi) => {
    try {
      let url = '';

      if (taskID === 'all') {
        url = `/decision_reviews/${businessLineUrl}/show-all-history`;
      } else {
        url = `/decision_reviews/${businessLineUrl}/tasks/${taskID}/show-history`;
      }
      // console.log(url);
      const response = await ApiUtil.get(url);

      // console.log(response);

      const events = response.body.data;

      // const preparedData = [];

      const preparedData = events.map(({ attributes, ...rest }) => ({ ...attributes, ...rest }));

      // console.log(events);

      // console.log(preparedData);

      // return thunkApi.fulfillWithValue('success', { analytics: true });

      return thunkApi.fulfillWithValue(preparedData, { analytics: true });

    } catch (error) {
      console.error(error);

      return thunkApi.rejectWithValue(`Event fetching failed: ${error.message}`, { analytics: true });
    }
  });

const changeHistorySlice = createSlice({
  name: 'changeHistory',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.
      addCase(downloadReportCSV.pending, (state) => {
        state.downloadReportCSV.status = 'loading';
      }).
      addCase(downloadReportCSV.fulfilled, (state) => {
        state.downloadReportCSV.status = 'succeeded';
      }).
      addCase(downloadReportCSV.rejected, (state, action) => {
        state.downloadReportCSV.status = 'failed';
        state.downloadReportCSV.error = action.error.message;
      }).
      addCase(fetchClaimEvents.pending, (state) => {
        state.fetchClaimEvents.status = 'loading';
      }).
      addCase(fetchClaimEvents.fulfilled, (state, action) => {
        state.fetchClaimEvents.status = 'succeeded';
        state.events = action.payload;
      }).
      addCase(fetchClaimEvents.rejected, (state, action) => {
        state.fetchClaimEvents.status = 'failed';
        state.fetchClaimEvents.error = action.error.message;
      });
  },
});

export default changeHistorySlice.reducer;
