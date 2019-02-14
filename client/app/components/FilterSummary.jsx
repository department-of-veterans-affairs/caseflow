import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

const FilterSummary = ({ filteredByList, alternateColumnNames, clearFilteredByList }) => {
  let filterSummary = null;
  let filterListContent = [];
  const clearAllFiltersLink = <button
    onClick={() => clearFilteredByList({})}
    className="cf-btn-link cf-clear-filters-link"> Clear all filters</button>;

  // Don't show anything if there are no filters.
  if (!_.isEmpty(filteredByList)) {
    for (const filter in filteredByList) { // eslint-disable-line guard-for-in
      // This condition might be met if filters were added and then later removed,
      // as there could still bea key in the filteredByList object pointing to an empty array.
      if (filteredByList[filter].length > 0) {
        const filterContent = (<span
          key={filter}> {alternateColumnNames ? alternateColumnNames[filter] : filter} ({filteredByList[filter].length})
        </span>);

        filterListContent = filterListContent.concat(filterContent);
      }
    }

    // Don't show anything if there are no filters.
    // This may be different than the first condition because when filters are added
    // and then later removed, there may still be a key in the filteredByList object
    // pointing to an empty array.
    if (filterListContent.length > 0) {
      // Add commas between filters
      filterListContent = filterListContent.map((element, index) => {
        if (index < filterListContent.length - 1) {
          return <span key={`filter-summary-element-${index}`}>{element}, </span>;
        }

        return element;
      });

      filterSummary = (
        <div className="cf-filter-summary">
          <strong>Filtering by:</strong>
          {filterListContent}
          <span>{clearAllFiltersLink}</span>
        </div>
      );
    }
  }

  return filterSummary;
};

FilterSummary.propTypes = {
  filteredByList: PropTypes.object.isRequired,
  clearFilteredByList: PropTypes.func.isRequired,
  alternateColumnNames: PropTypes.object
};

export default FilterSummary;
