// External Dependencies
import { sortBy, compact } from 'lodash';

// Local Dependencies
import { categoryFieldNameOfCategoryName } from 'app/reader/utils';
import { documentCategories } from 'app/reader/constants';

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
