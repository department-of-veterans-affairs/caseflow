// External Dependencies
import moment from 'moment';

// Local Dependencies
import { formatNameShort } from 'app/util/FormatUtil';
import { CACHE_TIMEOUT_HOURS, CATEGORIES } from 'store/constants/reader';

/**
 * Helper Method to format the redirect text in the `Back to Queue Link`
 * @param {object} props -- The format components for the redirect link
 */
export const formatRedirectText = ({ queueTaskType, veteranFullName, vbmsId }) => {
  // Set the Base text
  const text = '&lt; Back to ';

  // Set the text to your cases if there is no task type
  if (!queueTaskType) {
    return `${text}your cases`;
  }

  // Set the Text to the Task Type if we do not have the Veterans full name
  if (!veteranFullName) {
    return text + queueTaskType;
  }

  // Default to the Veterans name and VBMS ID
  return `${text}${veteranFullName} (${vbmsId})`;
};

/**
 * Helper Method to format the Appeal type based on claim info
 * @param {Object} claim -- The claim to determine the appeal info
 * @returns {string} -- The formatted appeal type
 */
export const formatAppealType = (claim) => {
  // Handle the Claim Type
  if (claim.cavc && claim.aod) {
    return 'AOD, CAVC';
  } else if (claim.cavc) {
    return 'CAVC';
  } else if (claim.aod) {
    return 'AOD';
  }

  // Default to return nothing
  return '';
};

/**
 * Helper Method to format the times for the Last Retrieval Alert
 * @param {string} manifestVbmsFetchedAt -- The last time the VBMS Manifest was fetched
 * @param {string} manifestVvaFetchedAt -- The last time the VVA Manifest was fetched
 */
export const formatAlertTime = (manifestVbmsFetchedAt, manifestVvaFetchedAt) => {
  // Create the formatted times
  const formattedTimes = {
    staleCacheTime: moment().subtract(CACHE_TIMEOUT_HOURS, 'h'),
    vbmsTimestamp: moment(manifestVbmsFetchedAt, 'MM/DD/YY HH:mma Z'),
    vvaTimestamp: moment(manifestVvaFetchedAt, 'MM/DD/YY HH:mma Z'),
  };

  // Calculate whether the cache is stale
  const stale = formattedTimes.vbmsTimestamp.isBefore(formattedTimes.staleCacheTime) ||
    formattedTimes.vvaTimestamp.isBefore(formattedTimes.staleCacheTime);

  // Check that document manifests have been received from VVA and VBMS
  if (stale) {
    // Calculate the time
    formattedTimes.now = moment();
    formattedTimes.vbmsDiff = formattedTimes.diff(formattedTimes.vbmsTimestamp, 'hours');
    formattedTimes.vvaDiff = formattedTimes.diff(formattedTimes.vvaTimestamp, 'hours');
  }

  // Return all of the Formatted Times
  return formattedTimes;
};

/**
 * Helper Method to format the Claims Folder Page Title
 * @param {Object} appeal -- Optional object containing veteran name
 * @returns {string} -- The title of the current page
 */
export const claimsFolderPageTitle = (appeal) => appeal && appeal.veteran_first_name ?
  `${formatNameShort(appeal.veteran_first_name, appeal.veteran_last_name)}'s Claims Folder` :
  'Claims Folder | Caseflow Reader';

/**
 * Helper Method to add `category_` to the name of the category
 * @param {string} categoryName -- The name of the category to format
 * @returns {string} -- The newly formatted category name
 */
export const formatCategoryName = (categoryName) => `category_${categoryName}`;

/**
 * Helper Method that character escapes certain characters for a RegExp
 * https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
 * @param {string} str -- The string to character escape
 * @returns {string|null} -- Either returns the escaped string or null
 */
export const escapeRegExp = (str) => {
  return str ? str.replace(/[-[\]/{}()*+?.\\^$|]/g, '\\$&') : null;
};

/**
 * Method to attach action meta data to the dispatch
 * @param {Object} payload -- The actual store payload
 * @param {string} action -- The action to which meta data is being attached
 * @param {string} label -- The analytics label
 */
export const addMetaLabel = (action, payload, label = '', meta = true) => ({
  payload,
  meta: meta && {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action,
      label
    }
  }
});
