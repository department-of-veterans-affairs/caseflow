import { ACTIONS } from '../constants';
import ApiUtil from '../../util/ApiUtil';
// import { analyticsCallback, submitIntakeCompleteRequest } from './intake';

// const analytics = true;

// Move this to utils or something
export const prepareFilters = (filterData) => {
  return filterData;
};

export const submitGenerateReport = (businessLineUrl, filterData) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_GENERATE_REPORT_REQUEST,
    // meta: { analytics }
  });

  // Do validation here or before with react hook forms?
  // const validationErrors =  validateReportData(filterData);

  // Data prep/transformation or cleanup, if neccessary.
  const data = prepareFilters(filterData);

  // TODO: Don't know if we want the analytics stuff that intake/queue has in some places.
  // Nor do I know how it works
  const getOptions = { query: data, headers: { Accept: 'text/csv' }, responseType: 'arraybuffer' };

  return ApiUtil.get(`/decision_reviews/${businessLineUrl}/report`, getOptions).then(
    (response) => {
      // console.log('getting back a response');

      // console.log(response);
      // Create a Blob from the array buffer
      const blob = new Blob([response.body], { type: 'text/csv' });

      // Access the filename from the response headers
      const contentDisposition = response.headers['content-disposition'];
      const matches = contentDisposition.match(/filename="(.+)"/);

      const filename = matches ? matches[1] : 'report.csv';

      // Create a download link
      const link = document.createElement('a');

      link.href = window.URL.createObjectURL(blob);
      link.download = filename;

      // Append the link to the document
      document.body.appendChild(link);

      // Trigger a click on the link to start the download
      link.click();

      // Remove the link from the document
      document.body.removeChild(link);

      dispatch({
        type: ACTIONS.SUBMIT_GENERATE_REPORT_SUCCESS,
        payload: {
          // intake: response.body
        },
        // meta: { analytics }
      });

      return true;
    },
    (error) => {
      console.log(error);
      // const responseObject = error.response.body;
      // const responseErrorCodes = responseObject.error_codes;

      dispatch({
        type: ACTIONS.SUBMIT_GENERATE_REPORT_FAILURE,
        payload: {
          // errorUUID: responseObject.error_uuid,
          // responseErrorCodes
        },
        // meta: {
        //   analytics: analyticsCallback
        // }
      });

      throw error;
    }
  );
};
