// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

// Local Dependencies
import { clearAllFilters } from 'app/reader/DocumentList/DocumentListActions';
import { filterMessageClass } from 'styles/reader/DocumentList/Header';
import { formatFilters } from 'utils/format';
import Button from 'app/components/Button';

/**
 * Filter Message Component
 * @param {Object} props -- Props include filter criteria
 */
export const FilterMessage = ({ docFilterCriteria }) => {
  // Create the Dispatcher
  const dispatch = useDispatch();

  // Get the filtered categories
  const filteredCategories = formatFilters(docFilterCriteria.tag, docFilterCriteria.category);

  return (
    <p className={filterMessageClass(filteredCategories)}>
       Filtering by: {filteredCategories}.
      <Button
        id="clear-filters"
        name="clear-filters"
        classNames={['cf-btn-link']}
        onClick={() => dispatch(clearAllFilters())}
      >
        Clear all filters.
      </Button>
    </p>
  );
};

FilterMessage.propTypes = {
  docFilterCriteria: PropTypes.object,
};
