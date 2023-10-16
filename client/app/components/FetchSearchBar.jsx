import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';
import SearchBar from '../components/SearchBar';
import { style } from 'glamor';
import { boldText } from '../queue/constants';
const FetchSearchBar = (props) => {
  const [searchText, setSearchText] = useState('');
  const handleSearchTextChange = (event) => {
    setSearchText(event);
  };

  const handleClick = (event) => {
    event.preventDefault();
    // props.setClaimEvidenceDocs('');
    ApiUtil.get(`/reader/appeal/${props.vacolsId}/document_content_searches?search_term=${searchText}`).
      then((response) => (props.setClaimEvidenceDocs(response.body.appealDocuments, searchText)));
  };

  return (
    <div style={{ width: '100%' }}>
      <p style={{ textAlign: 'center' }}>Search document contents</p>
      <span style={{
        width: '100%',
        display: 'flex',
        justifyContent: 'flex-end'
      }}>

<div style={{justifyContent: 'flex-end', width:'50%', marginRight:0}}>
<SearchBar value={searchText}
 onChange={handleSearchTextChange} size="small"
 onClearSearch={handleClearSearch}
 isSearchAhead={true}/>
 </div>
 <button className='cf-submit usa-button' onClick={handleClick}>Search</button>
      </span>
    </div>
  );
};

FetchSearchBar.propTypes = {
  vacolsId: PropTypes.string,
  setClaimEvidenceDocs: PropTypes.func.isRequired
};
export default FetchSearchBar;
