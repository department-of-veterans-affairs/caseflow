// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

// Local Dependencies
import StatusMessage from 'app/components/StatusMessage';
import { clearSearch } from 'app/reader/DocumentList/DocumentListActions';

/**
 * No Search Results Component
 * @param {Object} props -- Props containing the search query
 */
export const NoSearchResults = ({ searchQuery }) => {
  // Create the Dispatcher
  const dispatch = useDispatch();

  return (
    <div className="section--no-search-results">
      <StatusMessage title="Search results not found">
        Sorry! We couldn't find anything for "{searchQuery.trim()}."<br />
        Please search again or <a href="#" onClick={() => dispatch(clearSearch())}>go back to the document list.</a>
      </StatusMessage>
    </div>
  );
};

NoSearchResults.propTypes = {
  searchQuery: PropTypes.string
};
