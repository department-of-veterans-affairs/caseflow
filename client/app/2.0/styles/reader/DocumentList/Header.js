import classNames from 'classnames';

/**
 * Class for the Filter Message component
 * @param {array} categories -- The list of categories
 */
export const filterMessageClass = (categories) => classNames('document-list-filter-message', {
  hidden: !categories.length
});
