import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import FilterOption from '../../../app/components/FilterOption';

describe('FilterOption', () => {
  let wrapper;
  let props;

  beforeEach(() => {
    props = {
      options: [
        {
          value: 'AttorneyLegacyTask',
          checked: false
        },
        {
          value: 'EstablishClaim',
          checked: false
        }
      ],
      setSelectedValue: () => ({})
    };
  });

  context('renders', () => {
    it('works', () => {
      wrapper = mount(
        <FilterOption {...props} />
      );

      expect(wrapper.find('input[type="checkbox"]')).to.have.length(2);
    });
  });
});
