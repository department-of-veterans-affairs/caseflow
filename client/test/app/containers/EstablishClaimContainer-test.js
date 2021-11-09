import React from 'react';
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

  describe('sub-page', () => {
    it('renders', () => {
      expect(wrapper.find('.sub-page')).toHaveLength(1);
    });
  });

  describe('renders alerts', () => {
    it('hides alert if none in state', () => {
      expect(wrapper.state().alert).toBeNull();
      expect(wrapper.find('.usa-alert')).toHaveLength(0);
    });

    it('shows alert if alert in state', () => {
      expect(wrapper.state().alert).toBeNull();
      wrapper.find('.handleAlert').simulate('click');
      expect(wrapper.state().alert).not.toBeNull();
      expect(wrapper.find('.usa-alert')).toHaveLength(1);
    });

    it('clears alert when triggered', () => {
      wrapper.find('.handleAlert').simulate('click');
      expect(wrapper.state().alert).not.toBeNull();
      wrapper.find('.handleAlertClear').simulate('click');
      expect(wrapper.state().alert).toBeNull();
    });
  });
});
