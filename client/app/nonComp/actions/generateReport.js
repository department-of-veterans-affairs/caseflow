import { ACTIONS } from '../constants';
import ApiUtil from '../../util/ApiUtil';

// Move this to utils or something
export const prepareFilters = (filterData) => {
  return filterData;
};

const analytics = true;

export const submitGenerateReport = (businessLineUrl, filterData) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_GENERATE_REPORT_REQUEST,
    meta: { analytics }
  });

  // Data prep/transformation or cleanup, if neccessary.
  const data = prepareFilters(filterData);

  const getOptions = { query: data, headers: { Accept: 'text/csv' }, responseType: 'arraybuffer' };

  return ApiUtil.get(`/decision_reviews/${businessLineUrl}/report`, getOptions).then(
    (response) => {
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

      // Actions without a payload seem weird, but this is really just about managing the loading state
      dispatch({
        type: ACTIONS.SUBMIT_GENERATE_REPORT_SUCCESS,
        meta: { analytics }
      });

      return true;
    },
    (error) => {
      dispatch({
        type: ACTIONS.SUBMIT_GENERATE_REPORT_FAILURE,
        payload: {
          error
        },
        meta: { analytics }
      });

      throw error;
    }
  );
};
