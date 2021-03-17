// External Dependencies
import { sortBy } from 'lodash';

// Local Dependencies
import { categoryFieldNameOfCategoryName } from 'app/reader/utils';
import { documentCategories } from 'app/reader/constants';

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
