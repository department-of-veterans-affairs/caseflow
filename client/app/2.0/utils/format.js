import { compact } from 'lodash';

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
