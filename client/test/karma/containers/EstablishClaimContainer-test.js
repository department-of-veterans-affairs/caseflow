import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import { WrappingComponent } from '../establishClaim/WrappingComponent';
import EstablishClaimContainer from '../../../app/containers/EstablishClaimPage/EstablishClaimContainer';

describe('EstablishClaimContainer', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(<EstablishClaimContainer page="TestPage" otherProp="foo" />, {
      wrappingComponent: WrappingComponent
    });
  });

  context('sub-page', () => {
    it('renders', () => {
      expect(wrapper.find('.sub-page')).to.have.length(1);
    });
  });

  context('renders alerts', () => {
    it('hides alert if none in state', () => {
      expect(wrapper.state().alert).to.eq(null);
      expect(wrapper.find('.usa-alert')).to.have.length(0);
    });

    it('shows alert if alert in state', () => {
      expect(wrapper.state().alert).to.eq(null);
      wrapper.find('.handleAlert').simulate('click');
      expect(wrapper.state().alert).to.not.eq(null);
      expect(wrapper.find('.usa-alert')).to.have.length(1);
    });

    it('clears alert when triggered', () => {
      wrapper.find('.handleAlert').simulate('click');
      expect(wrapper.state().alert).to.not.eq(null);
      wrapper.find('.handleAlertClear').simulate('click');
      expect(wrapper.state().alert).to.eq(null);
    });
  });
});
