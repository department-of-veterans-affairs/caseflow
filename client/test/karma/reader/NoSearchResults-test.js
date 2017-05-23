import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import NoSearchResults from '../../../app/reader/NoSearchResults';

describe('NoSearchResults', () => {
  const getContext = () => mount(<NoSearchResults />);

  it('Shows proper search query message', () => {
    const query = 'hello there';
    const wrapper = getContext().setProps({ searchQuery: query });

    expect(wrapper.text()).to.include(`"${query}."`);
    expect(wrapper.text()).to.include('Search results not found');
  });
});
