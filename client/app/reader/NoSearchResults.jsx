import React from 'react';
import PropTypes from 'prop-types';
import StatusMessage from '../components/StatusMessage';

const NoSearchResults = (props) => (
  <div className="section--no-search-results">
    <StatusMessage
      title="Search results not found">
      Sorry! We couldn't find anything for "{props.searchQuery}."<br />
      Please search again or <a href="#" onClick={props.clearSearch}>go back to the document list.</a>
    </StatusMessage>
  </div>
);

NoSearchResults.propTypes = {
  clearSearch: PropTypes.func.isRequired,
  searchQuery: PropTypes.string
};

export default NoSearchResults;
