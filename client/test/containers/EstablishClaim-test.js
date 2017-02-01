import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import EstablishClaim, { ASSOCIATE_PAGE, FORM_PAGE, REVIEW_PAGE } from
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
          pending_eps: [],
          decisions: []
        },
        user: 'a'
      };

      /* eslint-enable camelcase */

      wrapper = mount(<EstablishClaim task={task}/>);

    });

    context('EstablishClaimForm', () => {
      beforeEach(() => {
        // Force component to Form page
        wrapper.setState({ page: FORM_PAGE });
      });

      it('shows cancel modal', () => {
        expect(wrapper.find('.cf-modal')).to.have.length(0);

        // click cancel to open modal
        wrapper.find('#button-Cancel').simulate('click');
        expect(wrapper.find('.cf-modal')).to.have.length(1);

        // Click go back and close modal
        wrapper.find('#Cancel-EP-Establishment-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal')).to.have.length(0);
      });
    });

    context('AssociateEP', () => {
      beforeEach(() => {
        wrapper.setState({ page: ASSOCIATE_PAGE });
      });

      it('shows cancel model', () => {
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);

        // click cancel to open modal
        wrapper.find('#button-Cancel').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(1);

        // Click go back and close modal
        wrapper.find('#Cancel-EP-Establishment-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);
      });
    });

    context('EstablishClaimReview', () => {
      beforeEach(() => {
        wrapper.setState({ page: REVIEW_PAGE });
      });

      it('shows special issues modal if special issue selected', () => {
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);

        // Click VAMC special issue checkbox
        wrapper.find('#vamc').simulate('change', { target: { checked: true } });

        // Click to create end product
        wrapper.find('#button-Create-End-Product').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(1);
      });

      it('shows cancel model', () => {
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);

        // click cancel to open modal
        wrapper.find('#button-Cancel').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(1);

        // Click go back and close modal
        wrapper.find('#Cancel-EP-Establishment-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);
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
          pending_eps: [],
          decisions: []
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
