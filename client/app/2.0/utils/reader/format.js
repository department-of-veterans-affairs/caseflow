import { formatNameShort } from 'app/util/FormatUtil';
import { CATEGORIES } from 'store/constants/reader';

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
