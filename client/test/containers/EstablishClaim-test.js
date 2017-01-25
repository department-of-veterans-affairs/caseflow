import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import EstablishClaim, { FORM_PAGE } from
  '../../app/containers/EstablishClaimPage/EstablishClaim';

describe('EstablishClaim', () => {
  context('.render', () => {
    let wrapper;

    beforeEach(() => {

      /* eslint-disable camelcase */
      const task = {
        appeal: {
          decision_type: 'Remand',
          non_canceled_end_products_within_30_days: [],
          pending_eps: []
        },
        user: 'a'
      };

      /* eslint-enable camelcase */

      wrapper = mount(<EstablishClaim task={task}/>);

      // Force component to Form page
      wrapper.setState({ page: FORM_PAGE });
    });

    context('when task is canceled', () => {
      beforeEach(() => {
        wrapper.find('#button-Cancel').simulate('click');
      });

      it('modal is shown', () => {
        expect(wrapper.find('.cf-modal')).to.have.length(1);
      });

      it('modal can be closed', () => {
        wrapper.find('#Cancel-EP-Establishment-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal')).to.have.length(0);
      });
    });
  });

  context('.getClaimTypeFromDecision', () => {
    let wrapper;

    beforeEach(() => {

      /* eslint-disable camelcase */
      const task = {
        appeal: {
          decision_type: 'Remand',
          non_canceled_end_products_within_30_days: [],
          pending_eps: []
        },
        user: 'a'
      };

      /* eslint-enable camelcase */

      wrapper = mount(<EstablishClaim task={task}/>);
    });

    it('returns 170RMDAMC - AMC-Remand for remand', () => {
      wrapper.setState({ reviewForm: { decisionType: { value: 'Remand' } } });
      expect(wrapper.instance().getClaimTypeFromDecision()).to.
        eql(['170RMDAMC', 'AMC-Remand']);
    });

    it('returns 170PGAMC - AMC-Partial Grant for partial', () => {
      wrapper.setState({ reviewForm: { decisionType: { value: 'Partial Grant' } } });
      expect(wrapper.instance().getClaimTypeFromDecision()).to.
        eql(['170PGAMC', 'AMC-Partial Grant']);
    });

    it('returns 172BVAG - BVA Grant for full', () => {
      wrapper.setState({ reviewForm: { decisionType: { value: 'Full Grant' } } });
      expect(wrapper.instance().getClaimTypeFromDecision()).to.
        eql(['172BVAG', 'BVA Grant']);
    });
  });
});
