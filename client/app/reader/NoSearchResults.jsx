import React from 'react';
import StatusMessage from '../components/StatusMessage';

const NoSearchResults = (props) => {
  return <div className="section--no-search-results">
    <StatusMessage
      title="Search results not found">
      Sorry! We couldn't find anything for "{props.searchQuery}."<br />
      Please search again or <a href="#" onClick={props.clearSearch}>go back to the document list.</a>
    </StatusMessage>
  </div>;
};

export default NoSearchResults;
