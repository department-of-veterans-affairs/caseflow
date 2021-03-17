// External Dependencies
import { sortBy, compact } from 'lodash';
import moment from 'moment';

// Local Dependencies
import { categoryFieldNameOfCategoryName } from 'app/reader/utils';
import { documentCategories } from 'app/reader/constants';

export const CACHE_TIMEOUT_HOURS = 3;

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
 * Helper Method to format the message for the filters in the document list header
 * @param {Object} tag -- The tags being filtered
 * @param {Object} category -- The category being filtered
 * @returns {string} -- The formatted filter message
 */
export const formatFilters = (tag, category) => {
  // Get the count of categories
  const catCount = compact(Object.values(category)).length;

  // Get the count of tags
  const tagCount = compact(Object.values(tag)).length;

  // Return the messages
  return compact([catCount && `Categories (${catCount})`, tagCount && `Issue tags (${tagCount})`]).join(', ');
};

/**
 * Helper Method to Format the Rows for the comments table
 * @param {array} documents -- The list of documents
 * @param {object} annotations -- The list of annotations for each document
 * @param {string} search -- The search query
 */
export const formatCommentRows = (documents, annotations, search) => {
  // This method will be filled in by a later PR, for now just return everything
  return {
    documents,
    annotations,
    search,
    rows: []
  };
};

/**
 * Helper Method to sort the Categories of a document
 * @param {Object} document -- Document object from the store
 */
export const sortCategories = (filtered, document) => {
  // Determine whether the categories should be filtered
  const categories = filtered ?
    documentCategories.filter((_, name) => document[categoryFieldNameOfCategoryName(name)]) :
    documentCategories;

  // Return the sorted categories
  return sortBy(categories, 'renderOrder');
};
