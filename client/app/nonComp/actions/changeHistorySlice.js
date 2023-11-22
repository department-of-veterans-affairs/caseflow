import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';
import querystring from 'querystring';

// Define the initial state
const initialState = {
  // We might not keep filters here and may only persist them in local state
  filters: [],
  status: 'idle',
  error: null,
};

// Move this to utils or something
const prepareFilters = (filterData) => {
  return filterData;
};

export const downloadReportCSV = createAsyncThunk('changeHistory/downloadReport',
  async ({ organizationUrl, filterData }, thunkApi) => {
  // Prepare data if neccessary. Although that could be reducer logic for filters if we end up using redux for it.
    const data = prepareFilters(filterData);

    console.log('data before being sent');
    console.log(data);

    console.log(querystring.stringify(data));
    console.log(JSON.stringify(data));

    try {
      const postData = ApiUtil.convertToSnakeCase(data);
      const getOptions = { query: postData.filters, headers: { Accept: 'text/csv' }, responseType: 'arraybuffer' };
      const response = await ApiUtil.get(`/decision_reviews/${organizationUrl}/report`, getOptions);

      // New post attempt instead of get because get is lame
      // const postData = JSON.stringify(ApiUtil.convertToSnakeCase(data));
      // const postData = ApiUtil.convertToSnakeCase(data);
      // const { response } = await ApiUtil.post(`/decision_reviews/${organizationUrl}/report`, { data: postData, headers: { Accept: 'text/csv' } });
      // const response = await ApiUtil.post(`/decision_reviews/${organizationUrl}/report`, { data: postData.filters, headers: { Accept: 'text/csv' }, responseType: 'arraybuffer' });

      console.log(response);
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

const changeHistorySlice = createSlice({
  name: 'changeHistory',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.
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
