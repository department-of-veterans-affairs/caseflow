import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';
import SearchBar from '../components/SearchBar';

const FetchSearchBar = (props) => {
  const [searchText, setSearchText] = useState('');
  const handleSearchTextChange = (newValue) => {
    setSearchText(newValue);
  };

  const handleClearSearch = () => {
    setSearchText('');
    props.clearClaimEvidenceDocs();
  };

  const handleClick = (event) => {
    event.preventDefault();
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
      <p style={{ textAlign: 'left', marginLeft: '.5%' }}>Search document contents</p>
      <span style={{
        width: '100%',
        display: 'flex',
        justifyContent: 'flex-start'
      }}>
        <div style={{ display:'flex', width: 'fit-content', marginRight: 0, marginLeft: 10, flexDirection: 'column',  }}>
          <SearchBar value={searchText}
            onChange={handleSearchTextChange} size="small"
            onClearSearch={handleClearSearch}
            isSearchAhead />
          <button id="fetchDocumentContentsButton" className="cf-submit usa-button" onClick={handleClick} style={{
            marginLeft: '0%',
            display: 'left',
          }}>Search</button></div>
      </span>
    </div>
  );
};

FetchSearchBar.propTypes = {
  vacolsId: PropTypes.string,
  setClaimEvidenceDocs: PropTypes.func.isRequired,
  clearClaimEvidenceDocs: PropTypes.func.isRequired
};
export default FetchSearchBar;
