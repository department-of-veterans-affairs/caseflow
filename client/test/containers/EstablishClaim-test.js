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
        appeal: { decision_type: 'Remand' },
        user: 'a'
      };

      /* eslint-enable camelcase */

      wrapper = mount(<EstablishClaim task={task}/>);

      // Force component to Form page
      wrapper.setState({ page: FORM_PAGE });
    });

    context('when POA is None', () => {
      beforeEach(() => {
        wrapper.find('#POA_None').simulate('change');
      });

      it('hides POA code textfield', () => {
        expect(wrapper.find('#POACode')).to.have.length(0);
      });
      it('hides Allow POA access checkbox', () => {
        expect(wrapper.find('#AllowPOA')).to.have.length(0);
      });
    });

    context('when POA is VSO', () => {
      beforeEach(() => {
        wrapper.find('#POA_VSO').simulate('change');
      });

      it('show POA code textfield', () => {
        expect(wrapper.find('#POACode')).to.have.length(1);
      });
      it('show Allow POA access checkbox', () => {
        expect(wrapper.find('#allowPoa')).to.have.length(1);
      });
    });

    context('when POA is Private', () => {
      beforeEach(() => {
        wrapper.find('#POA_Private').simulate('change');
      });

      it('show POA code textfield', () => {
        expect(wrapper.find('#POACode')).to.have.length(1);
      });
      it('show Allow POA access checkbox', () => {
        expect(wrapper.find('#allowPoa')).to.have.length(1);
      });
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
      const task = {
        appeal: 'b',
        user: 'a'
      };

      wrapper = mount(<EstablishClaim task={task}/>);
    });

    it('returns 170RMDAMC - AMC-Remand for remand', () => {
      wrapper.setState({ reviewForm: { decisionType: { value: 'Remand' } } });
      expect(wrapper.instance().getClaimTypeFromDecision()).to.
        eql(['170RMDAMC',  'AMC-Remand']);
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
