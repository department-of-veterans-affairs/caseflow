// External Dependencies
import querystring from 'querystring';
import moment from 'moment';
import { sortBy, compact } from 'lodash';

// Local Dependencies
import { formatNameShort } from 'app/util/FormatUtil';
import { documentCategories, CACHE_TIMEOUT_HOURS, CATEGORIES } from 'store/constants/reader';

/**
 * Helper Method to add `category_` to the name of the category
 * @param {string} categoryName -- The name of the category to format
 * @returns {string} -- The newly formatted category name
 */
export const formatCategoryName = (categoryName) => `category_${categoryName}`;

/**
 * Helper Method to format the Filter Criteria
 * @param {Object} filterCriteria -- The object containing filter criteria
 */
export const formatFilterCriteria = (filterCriteria) => {
  // Create the filter object
  const filters = {
    category: Object.keys(filterCriteria.category).filter((cat) => filterCriteria.category[cat] === true).
      map((key) => formatCategoryName(key)),
    tag: Object.keys(filterCriteria.tag).filter((tag) => filterCriteria.tag[tag] === true),
    searchQuery: filterCriteria.searchQuery.toLowerCase()
  };

  // Map the active filters
  const active = Object.keys(filters).filter((activeFilter) => filters[activeFilter].length).
    map((activeFilter) => filters[activeFilter]);

  // Return the filters and the active filters
  return { filters, active };
};

/**
 * Helper Method to sort the Categories of a document
 * @param {Object} document -- Document object from the store
 */
export const sortCategories = (document) => {
  // Determine whether the categories should be filtered
  const categories = Object.keys(documentCategories).filter((name) => document[formatCategoryName(name)]).
    map((cat) => documentCategories[cat]);

  // Return the sorted categories
  return sortBy(categories, 'renderOrder');
};

/**
 * This is a dummy method that will be replaced in a later part of the stack
 */
export const formatDocumentRows = () => [];

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
 * Helper Method to format the redirect text in the `Back to Queue Link`
 * @param {object} props -- The format components for the redirect link
 */
export const formatRedirectText = ({ queueTaskType, veteranFullName, vbmsId }) => {
  // Set the Base text
  const text = '< Back to ';

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
export const formatAppealType = ({ claim }) => {
  // Handle the Claim Type
  if (claim?.cavc && claim?.aod) {
    return 'AOD, CAVC';
  } else if (claim?.cavc) {
    return 'CAVC';
  } else if (claim?.aod) {
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
    formattedTimes.vbmsDiff = formattedTimes.now.diff(formattedTimes.vbmsTimestamp, 'hours');
    formattedTimes.vvaDiff = formattedTimes.now.diff(formattedTimes.vvaTimestamp, 'hours');
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

/**
 * Helper Method to Parse the Queue Redirect URL from the window
 * @returns {string|null} -- The Parsed Queue Redirect URL
 */
export const getQueueRedirectUrl = () => {
  // Parse the Redirect URL string from the URL bar
  const query = querystring.parse(window.location.search.slice(1));

  // Return either the parsed URL or null
  return query.queue_redirect_url ? decodeURIComponent(query.queue_redirect_url) : null;
};

/**
 * Helper Method to Parse the Task Type from the window
 * @returns {string|null} -- The Parsed Queue Task Type
 */
export const getQueueTaskType = () => {
  // Parse the Task Type string from the URL bar
  const query = querystring.parse(window.location.search.slice(1));

  // Return either the parsed Task Type or null
  return query.queue_task_type ? decodeURIComponent(query.queue_task_type) : null;
};

/**
 * Helper Method to Parse the Task Type from the window
 * @returns {string|null} -- The Parsed Queue Task Type
 */
export const formatCommentQuery = () => {
  // Parse the Task Type string from the URL bar
  const query = querystring.parse(window.location.search.slice(0))['?annotation'];

  // Convert to Int or null and return
  return query ? parseInt(query, 10) : null;
};

/**
 * Helper Method to map tags to appropriate options in the SearchableDropdown
 * @param {Array} tags -- List of tags to be formatted
 */
export const formatTagValue = (tags) => tags.map((tag) => ({
  value: tag.text,
  label: tag.text,
  tagId: tag.id
}));

/**
 * Helper Method to map tags to appropriate options in the SearchableDropdown
 * @param {Array} tags -- List of tags to be formatted
 */
export const formatTagOptions = (documents) => Object.values(documents).
  reduce((list, doc) => [...list, ...doc.tags], []).
  filter((tag, index, list) => list.findIndex((item) => item.text === tag.text) === index);
