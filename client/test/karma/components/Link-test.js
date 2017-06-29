import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import CaseflowLink from '../../../app/components/Link';
import { Link } from 'react-router-dom';

describe('Link', () => {
  const to = 'test';
  let wrapper;

  before(() => {
    wrapper = shallow(<CaseflowLink to={to}>Test</CaseflowLink>);
  });

  it('renders Router Link', () => {
    expect(wrapper.find(Link).props()).to.include({ to });
  });

  context('has correct class names for button type', () => {
    it('for primary', () => {
      wrapper.setProps({ button: 'primary' });
      expect(wrapper.find(Link).props()).to.include({ className: 'usa-button' });
    });

    it('for secondary', () => {
      wrapper.setProps({ button: 'secondary' });
      expect(wrapper.find(Link).props()).to.include({ className: 'usa-button-outline' });
    });

    it('for disabled', () => {
      wrapper.setProps({ button: 'disabled' });
      expect(wrapper.find('p').props()).to.include({ className: 'usa-button-disabled' });
    });
  });

});
