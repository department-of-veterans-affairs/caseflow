// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import StatusMessage from 'app/components/StatusMessage';

/**
 * No Search Results Component
 * @param {Object} props -- Props containing the search query
 */
export const NoSearchResults = ({ show, filterCriteria, clearSearch }) => show && (
  <div className="section--no-search-results">
    <StatusMessage title="Search results not found">
        Sorry! We couldn't find anything for "{filterCriteria.searchQuery.trim()}."<br />
        Please search again or <a href="#" onClick={clearSearch}>go back to the document list.</a>
    </StatusMessage>
  </div>
);

NoSearchResults.propTypes = {
  show: PropTypes.bool,
  filterCriteria: PropTypes.object,
  clearSearch: PropTypes.func
};
