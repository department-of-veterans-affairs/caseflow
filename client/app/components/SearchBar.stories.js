import React, { useState } from 'react';

import SearchBar from './SearchBar';

const handleSearchClick = (setLoadingFn) => {
  setLoadingFn(true);

  setTimeout(() => setLoadingFn(false), 2000);
};

const Template = (args) => <span className={args.parentClassName} ><SearchBar {...args} /></span>;

const Controlled = (args) => {
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
    />
  </span>);
};

export const Big = Template.bind({});

export const Small = Template.bind({});
Small.args = { size: 'small' };

export const Label = Template.bind({});
Label.args = { title: 'This is a title' };

export const Internal = Template.bind({});
Internal.args = { size: 'small', internalText: 'Text' };

export const Loading = Template.bind({});
Loading.args = { loading: true };

export const SearchAhead = Template.bind({});
SearchAhead.args = { isSearchAhead: true, parentClassName: ' cf-search-ahead-parent' };

export const Callbacks = Controlled.bind({});
