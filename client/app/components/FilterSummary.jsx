import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import COPY from '../../COPY';

const ALTERNATE_COLUMN_NAMES = {
  'appeal.caseType': 'Case Type',
  'appeal.docketName': COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
  'assignedTo.name': COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
  'closestRegionalOffice.location_hash.city': 'Regional Office',
  'appeal.issueTypes': 'Issue Type',
  readableRequestType: 'Hearing Type',
  regionalOffice: 'Regional Office',
  vlj: 'VLJ',
  label: 'Tasks',
  suggestedLocation: 'Suggested Location',
  hearingLocation: 'Hearing Location'
};

const FilterSummary = ({ filteredByList, clearFilteredByList }) => {
  let filterSummary = null;
  let filterListContent = [];
  const clearAllFiltersLink = <button
    onClick={() => clearFilteredByList({})}
    className="cf-btn-link cf-clear-filters-link"> Clear all filters</button>;

  // Don't show anything if there are no filters.
  if (!_.isEmpty(filteredByList)) {
    for (const filter in filteredByList) { // eslint-disable-line guard-for-in
      // This condition might be met if filters were added and then later removed,
      // as there could still be a key in the filteredByList object pointing to an empty array.
      if (filteredByList[filter].length > 0) {
        const filterContent = (<span
          key={filter}> {ALTERNATE_COLUMN_NAMES[filter] ? ALTERNATE_COLUMN_NAMES[filter] : filter} (
          {filteredByList[filter].length})
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
  clearFilteredByList: PropTypes.func.isRequired
};

export default FilterSummary;
