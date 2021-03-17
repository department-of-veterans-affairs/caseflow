import ApiUtil from 'app/util/ApiUtil';
import { ENDPOINT_NAMES } from 'app/reader/analytics';

/**
 * Helper Method to record the search value for analytics purposes. Don't worry if it fails
 * @param {string} query -- The Query being used to search
 */
export const recordSearch = async (vacolsId, query) => {
  try {
    await ApiUtil.post(
      `/reader/appeal/${vacolsId}/claims_folder_searches`,
      { data: { query } },
      ENDPOINT_NAMES.CLAIMS_FOLDER_SEARCHES
    );
  } catch (error) {
    // we don't care reporting via Raven.
    console.error(error);
  }
};
