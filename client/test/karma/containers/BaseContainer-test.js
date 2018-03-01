import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import BaseContainer from '../../../app/containers/BaseContainer';

describe('BaseContainer', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(<BaseContainer page="TestPage" otherProp="foo" />);
  });

  context('sub-page', () => {
    it('renders', () => {
      expect(wrapper.find('.sub-page')).to.have.length(1);
    });
  });
});
