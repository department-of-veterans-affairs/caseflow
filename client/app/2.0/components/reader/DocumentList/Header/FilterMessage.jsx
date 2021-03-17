// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { filterMessageClass } from 'styles/reader/DocumentList/Header';
import { formatFilters } from 'utils/reader';
import Button from 'app/components/Button';

/**
 * Filter Message Component
 * @param {Object} props -- Props include filter criteria
 */
export const FilterMessage = ({ filterCriteria, clearAllFilters }) => {
  // Get the filtered categories
  const filteredCategories = formatFilters(filterCriteria.tag, filterCriteria.category);

  return (
    <p className={filterMessageClass(filteredCategories)}>
       Filtering by: {filteredCategories}.
      <Button
        id="clear-filters"
        name="clear-filters"
        classNames={['cf-btn-link']}
        onClick={clearAllFilters}
      >
        Clear all filters.
      </Button>
    </p>
  );
};

FilterMessage.propTypes = {
  filterCriteria: PropTypes.object,
  clearAllFilters: PropTypes.func,
};
