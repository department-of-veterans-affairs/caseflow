import React from 'react';
import { mount } from 'enzyme';

import BaseContainer from '../../../app/containers/BaseContainer';

describe('BaseContainer', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(<BaseContainer page="TestPage" otherProp="foo" />);
  });

  describe('sub-page', () => {
    it('renders', () => {
      expect(wrapper.find('.sub-page')).toHaveLength(1);
    });
  });
});
