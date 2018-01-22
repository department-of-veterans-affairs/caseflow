import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import EstablishClaim, { DECISION_PAGE, FORM_PAGE, NOTE_PAGE } from
  '../../../app/containers/EstablishClaimPage/EstablishClaim';
import * as Constants from '../../../app/establishClaim/constants';
import { findElementById } from '../../helpers';

let func = function() {
  // empty function
};

describe('EstablishClaim', () => {
  context('.render', () => {
    let wrapper;

    beforeEach(() => {

      /* eslint-disable camelcase */
      const task = {
        appeal: {
          vbms_id: '516517691',
          dispatch_decision_type: 'Remand',
          decisions: [{
            label: null
          }],
          non_canceled_end_products_within_30_days: [],
          pending_eps: [],
          station_key: '397',
          regional_office_key: 'RO11'
        },
        user: 'a'
      };

      /* eslint-enable camelcase */

      const regionalOfficeCities = {
        RO11: {
          city: 'Pittsburgh',
          state: 'PA',
          timezone: 'America/New_York'
        }
      };

      wrapper = mount(<EstablishClaim
        regionalOfficeCities={regionalOfficeCities}
        pdfLink=""
        pdfjsLink=""
        handleAlert={func}
        handleAlertClear={func}
        task={task} />);

    });

    context('EstablishClaimForm', () => {
      beforeEach(() => {
        wrapper.instance().store.dispatch({
          type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
          payload: {
            field: 'stationOfJurisdiction',
            value: '397'
          }
        });
        // Force component to Form page
        wrapper.setState({ page: FORM_PAGE });
      });

      it('shows cancel modal', () => {
        expect(wrapper.find('.cf-modal')).to.have.length(0);

        // click cancel to open modal
        wrapper.find('#button-Cancel').simulate('click');
        expect(wrapper.find('.cf-modal')).to.have.length(1);

        // Click go back and close modal
        findElementById(wrapper, 'Stop-Processing-Claim-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal')).to.have.length(0);
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
        findElementById(wrapper, 'Stop-Processing-Claim-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);
      });
    });

    context('EstablishClaimNote', () => {
      beforeEach(() => {
        wrapper.instance().store.dispatch({
          type: Constants.CHANGE_SPECIAL_ISSUE,
          payload: {
            specialIssue: 'mustardGas',
            value: true
          }
        });
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
    let task, wrapper;

    const mountApp = (decisionType, stationOfJurisdiction = '397') => {
      task.appeal.dispatch_decision_type = decisionType;

      wrapper = mount(<EstablishClaim
        regionalOfficeCities={{}}
        pdfLink=""
        pdfjsLink=""
        handleAlert={func}
        handleAlertClear={func}
        task={task} />);

      if (stationOfJurisdiction !== '397') {
        wrapper.instance().store.dispatch({
          type: Constants.CHANGE_SPECIAL_ISSUE,
          payload: {
            specialIssue: 'mustardGas',
            value: true
          }
        });
      }

      wrapper.instance().store.dispatch({
        type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
        payload: {
          field: 'stationOfJurisdiction',
          value: stationOfJurisdiction
        }
      });
    };

    beforeEach(() => {

      /* eslint-disable camelcase */
      task = {
        appeal: {
          vbms_id: '516517691',
          dispatch_decision_type: 'Remand',
          decisions: [{
            label: null
          }],
          non_canceled_end_products_within_30_days: [],
          pending_eps: []
        },
        user: 'a'
      };
      /* eslint-enable camelcase */
    });

    context('when ARC EP', () => {
      it('returns proper values for remand', () => {
        mountApp('Remand');
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['070RMNDARC', 'ARC Remand (070)']);
      });

      it('returns proper values for partial grant', () => {
        mountApp('Partial Grant');
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['070RMBVAGARC', 'ARC Remand with BVA Grant']);
      });

      it('returns proper values for full grant', () => {
        mountApp('Full Grant');
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['070BVAGRARC', 'ARC BVA Grant']);
      });
    });

    context('when Routed EP', () => {
      it('returns proper value for remand', () => {
        mountApp('Remand', '301');
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['070RMND', 'Remand (070)']);
      });

      it('returns proper value for partial grant', () => {
        mountApp('Partial Grant', '301');
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['070RMNDBVAG', 'Remand with BVA Grant (070)']);
      });

      it('returns proper value for full grant', () => {
        mountApp('Full Grant', '301');
        expect(wrapper.instance().getClaimTypeFromDecision()).to.
          eql(['070BVAGR', 'BVA Grant (070)']);
      });
    });
  });
});
