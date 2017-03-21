import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import EstablishClaim, { DECISION_PAGE, ASSOCIATE_PAGE, FORM_PAGE, NOTE_PAGE } from
  '../../app/containers/EstablishClaimPage/EstablishClaim';

describe('EstablishClaim', () => {
  context('.render', () => {
    let wrapper;

    beforeEach(() => {

      /* eslint-disable camelcase */
      const task = {
        appeal: {
          decision_type: 'Remand',
          decisions: [{
            label: null
          }],
          non_canceled_end_products_within_30_days: [],
          pending_eps: []
        },
        user: 'a'
      };

      /* eslint-enable camelcase */

      wrapper = mount(<EstablishClaim task={task}/>);

    });

    context('navigation', () => {
      it('initially loads to decision page', () => {
        expect(wrapper.state().history.location.pathname).to.equal('/decision');
        expect(wrapper.state().page).to.equal('decision');
      });

      it('redirects to decision if no existing EPs', (done) => {
        // Add a listener to the history object and look for the "go back" POP event
        let unlisten = wrapper.state().history.listen((location, action) => {
          if (action === 'POP') {
            expect(wrapper.state().history.location.pathname).to.equal('/decision');
            unlisten();
            done();
          }
        });

        // manually navigate to associate EP page
        // This simulates a user manually altering the URL
        wrapper.state().history.push('associate');
      });
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
        wrapper.find('#Stop-Processing-Claim-button-id-0').simulate('click');
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
        wrapper.find('#Stop-Processing-Claim-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);
      });
    });

    context('EstablishClaimDecision', () => {
      beforeEach(() => {
        wrapper.setState({ page: DECISION_PAGE });
      });

      it('shows cancel model', () => {
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);

        // click cancel to open modal
        wrapper.find('#button-Cancel').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(1);

        // Click go back and close modal
        wrapper.find('#Stop-Processing-Claim-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);
      });
    });

    context('EstablishClaimNote', () => {
      beforeEach(() => {
        wrapper.getNode().handleFieldChange('specialIssues', 'mustardGas')(true);
        wrapper.setState({ reviewForm: { decisionType: { value: 'Full Grant' } } });
        wrapper.setState({ page: NOTE_PAGE });
      });

      it('route claim button is disabled until checkbox is checked', () => {
        // button is disabled
        expect(wrapper.find('.usa-button-disabled')).to.have.length(1);

        // click checkbox
        wrapper.find('#confirmNote').simulate('change', { target: { checked: true } });

        // button is enabled
        expect(wrapper.find('.usa-button-primary')).to.have.length(1);
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
          decisions: [{
            label: null
          }],
          non_canceled_end_products_within_30_days: [],
          pending_eps: []
        },
        user: 'a'
      };

      /* eslint-enable camelcase */

      wrapper = mount(<EstablishClaim task={task}/>);
    });

    context("when ARC EP", () => {
      beforeEach(() => {
        wrapper.setState({
          claimForm: { stationOfJurisdiction: { value: "397 - ARC" } }
        });
      });

      it('returns 170RMDAMC - ARC-Remand for remand', () => {
        wrapper.setState({ reviewForm: { decisionType: { value: 'Remand' } } });
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['170RMDAMC', 'ARC-Remand']);
      });

      it('returns 170PGAMC - ARC-Partial Grant for partial', () => {
        wrapper.setState({ reviewForm: { decisionType: { value: 'Partial Grant' } } });
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['170PGAMC', 'ARC-Partial Grant']);
      });

      it('returns 172BVAG - BVA Grant for full', () => {
        wrapper.setState({ reviewForm: { decisionType: { value: 'Full Grant' } } });
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['172BVAG', 'BVA Grant']);
      });
    });

    context("when Routed EP", () => {
      beforeEach(() => {
        wrapper.setState({
          claimForm: { stationOfJurisdiction: { value: "322 - Montgomery, AL" } }
        });
      });

      it('returns 170RMDAMC - ARC-Remand for remand', () => {
        wrapper.setState({ reviewForm: { decisionType: { value: 'Remand' } } });
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['170RMD', 'Remand']);
      });

      it('returns 170PGAMC - ARC-Partial Grant for partial', () => {
        wrapper.setState({ reviewForm: { decisionType: { value: 'Partial Grant' } } });
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['170RBVAG', 'Remand with BVA Grant']);
      });

      it('returns 172BVAG - BVA Grant for full', () => {
        wrapper.setState({ reviewForm: { decisionType: { value: 'Full Grant' } } });
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['172BVAG', 'BVA Grant']);
      });
    });
  });
});
