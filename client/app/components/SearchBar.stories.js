import React, { useState } from 'react';

import SearchBar from './SearchBar';

const handleSearchClick = (setLoadingFn) => {
  setLoadingFn(true);

  setTimeout(() => setLoadingFn(false), 2000);
};

const Template = (args) => {
  const [val, setVal] = useState('');
  const [loading, setLoading] = useState(false);
  const handleClick = () => handleSearchClick(setLoading);
  const clearVal = () => setVal('');

  return (<span className={args.parentClassName} >
    <SearchBar
      {...args}
      onChange={setVal}
      onSubmit={handleClick}
      onClearSearch={clearVal}
      loading={loading}
      value={val}
      placeholder="Type to search..."
      submitUsingEnterKey
    />
  </span>);
};

export const Big = Template.bind({});
Big.args = { id: 'search-big', title: 'Search Big', size: 'big' };

export const Small = Template.bind({});
Small.args = { id: 'search-small', title: 'Search Small', size: 'small' };

export const SearchAhead = Template.bind({});
SearchAhead.args = {
  id: 'search-ahead',
  title: 'Search Ahead',
  size: 'small',
  isSearchAhead: true,
  parentClassName: ' cf-search-ahead-parent'
};
