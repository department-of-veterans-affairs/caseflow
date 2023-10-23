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

  const handleClick = () => {
    // nil and empty error handling of input value
    if (searchText && searchText.trim().length !== 0) {
      ApiUtil.get(`/reader/appeal/${props.vacolsId}/document_content_searches?search_term=${searchText}`).
        then((response) => (props.setClaimEvidenceDocs(response.body.appealDocuments, searchText)));
    }
  };

  const resetFetchBarState = () => {
    setSearchText('');
  };

  useEffect(() => {
    props.setClearAllFiltersCallbacks([resetFetchBarState]);
  }, resetFetchBarState);

  return (
    <div style={{ width: '100%', height: '200px', backgroundColor: 'white' }}>
      <p style={{ backgroundColor: 'lightgrey', width: '100%', height: '50px', textAlign: 'left', paddingLeft: '10px' }}> Search document contents </p>
      <p style={{ textAlign: 'left', paddingLeft: '10px', height: '5px' }}>Search document contents</p>
      <span style={{
        width: '75%',
        display: 'flex',
        justifyContent: 'flex-end'
      }}>
      </span>
      <div style={{ display: 'flex', paddingLeft: '10px' }}>
        <SearchBar
          style={{ display: 'flex', paddingLeft: '25px', height: '0px' }}
          value={searchText}
          onChange={handleSearchTextChange}
          onSubmit={handleClick}
          size="big"
          onClearSearch={handleClearSearch}
          submitUsingEnterKey
        />
      </div>
    </div>
  );
};

FetchSearchBar.propTypes = {
  vacolsId: PropTypes.string,
  setClaimEvidenceDocs: PropTypes.func.isRequired,
  clearClaimEvidenceDocs: PropTypes.func.isRequired
};
export default FetchSearchBar;
