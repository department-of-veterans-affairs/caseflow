import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { sortCategories } from 'utils/reader';

/**
 * Category Icons Component
 * @param {Object} props -- Contains search category highlights and the document
 */
export const CategoryIcons = ({ searchCategoryHighlights, doc }) => {
  // Sort the Categories by the document and apply a filter
  const categories = sortCategories(doc);

  return categories.length && (
    <ul className="cf-document-category-icons" aria-label="document categories">
      {categories.map((category) => {
        // Set the highlighted value
        const highlighted = searchCategoryHighlights[category.humanName.split(' ')[0].toLowerCase()];

        return (
          <li
            className={highlighted ? 'cf-no-styling-list highlighted' : 'cf-no-styling-list'}
            key={category.renderOrder}
            aria-label={category.humanName}
          >
            {category.svg}
          </li>
        );
      })}
    </ul>
  );
};

CategoryIcons.defaultProps = {
  searchCategoryHighlights: {}
};

CategoryIcons.propTypes = {
  doc: PropTypes.object.isRequired,
  searchCategoryHighlights: PropTypes.object
};
