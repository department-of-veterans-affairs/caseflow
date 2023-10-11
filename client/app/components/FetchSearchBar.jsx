import React, { useState } from 'react';
import ApiUtil from '../util/ApiUtil';

const FetchSearchBar = () => {
  const [searchText, setSearchText] = useState('');
  const handleSearchTextChange = (event) => {
    setSearchText(event.target.value);
  };

  const handleClick = (event) => {
    event.preventDefault();
    ApiUtil.get(`/reader/appeal/:appeal_id/document_content_searches?search_term=${searchText}`)
      .then((response) => console.log(response));
  };

  return (
    <div style={{ width: '100%' }}>
      <p style={{ textAlign: 'center' }}>Search document contents</p>
      <span style={{
        width: '100%',
        display: 'flex',
        justifyContent: 'flex-end'
      }}>
        <input value={searchText} onChange={handleSearchTextChange} />
        <button className='cf-submit usa-button' onClick={handleClick}>Search</button>
      </span>
    </div>
  );
};

export default FetchSearchBar;
