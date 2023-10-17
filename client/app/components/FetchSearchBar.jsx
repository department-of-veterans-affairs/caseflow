import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';

const FetchSearchBar = (props) => {
  const [searchText, setSearchText] = useState('');
  const handleSearchTextChange = (event) => {
    setSearchText(event.target.value);
  };

  const handleClick = (event) => {
    event.preventDefault();
    // props.setClaimEvidenceDocs('');
    ApiUtil.get(`/reader/appeal/${props.vacolsId}/document_content_searches?search_term=${searchText}`).
      then((response) => (props.setClaimEvidenceDocs(response.body.appealDocuments, searchText)));
  };

  const resetFetchBarState = () => {
    setSearchText('');
  };

  useEffect(() => {
    props.setClearAllFiltersCallbacks([resetFetchBarState]);
  }, resetFetchBarState);

  return (
    <div style={{ width: '100%' }}>
      <p style={{ textAlign: 'center' }}>Search document contents</p>
      <span style={{
        width: '100%',
        display: 'flex',
        justifyContent: 'flex-end'
      }}>
        <input id="fetchDocumentsInput" aria-label="search bar for fetching document conents."
          value={searchText} onChange={handleSearchTextChange} />
        <button id="fetchDocumentContentsButton" className="cf-submit usa-button" onClick={handleClick}>Search</button>
      </span>
    </div>
  );
};

FetchSearchBar.propTypes = {
  vacolsId: PropTypes.string,
  setClaimEvidenceDocs: PropTypes.func.isRequired,
  setClearAllFiltersCallbacks: PropTypes.func.isRequired
};
export default FetchSearchBar;
