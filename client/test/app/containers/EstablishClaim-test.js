import React from 'react';
import { mount } from 'enzyme';
import EstablishClaim, {
  DECISION_PAGE,
  FORM_PAGE,
  NOTE_PAGE
} from '../../../app/containers/EstablishClaimPage/EstablishClaim';
import * as Constants from '../../../app/establishClaim/constants';
import { findElementById } from '../../helpers';
import { WrappingComponent, store } from '../establishClaim/WrappingComponent';
import bootstrapRedux from '../../../app/establishClaim/reducers/bootstrap';
import { createStore } from 'redux';

let func = function() {
  // empty function
};

describe('EstablishClaim', () => {
  describe('.render', () => {
    let wrapper;

    beforeEach(() => {
      /* eslint-disable camelcase */
      const task = {
        appeal: {
          vbms_id: '516517691',
          dispatch_decision_type: 'Remand',
          decisions: [
            {
              label: null
            }
          ],
          non_canceled_end_products_within_30_days: [],
          pending_eps: [],
          station_key: '397',
          regional_office_key: 'RO11',
          serialized_decision_date: '2019-01-01'
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

      wrapper = mount(
        <EstablishClaim
          regionalOfficeCities={regionalOfficeCities}
          pdfLink=""
          pdfjsLink=""
          handleAlert={func}
          handleAlertClear={func}
          task={task}
        />,
        {
          wrappingComponent: WrappingComponent
        }
      );
    });

    describe('EstablishClaimForm', () => {
      beforeEach(() => {
        store.dispatch({
          type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
          payload: {
            field: 'stationOfJurisdiction',
            value: '397'
          }
        });
        // Force component to Form page
        wrapper.
          find('EstablishClaim').
          instance().
          setState({ page: FORM_PAGE });
        wrapper.update();
      });

      it('shows cancel modal', () => {
        expect(wrapper.find('.cf-modal')).toHaveLength(0);

        // click cancel to open modal
        wrapper.find('#button-Cancel').simulate('click');
        expect(wrapper.find('.cf-modal')).toHaveLength(1);

        // Click go back and close modal
        findElementById(wrapper, 'Stop-Processing-Claim-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal')).toHaveLength(0);
      });
    });

    describe('EstablishClaimDecision', () => {
      beforeEach(() => {
        wrapper.
          find('EstablishClaim').
          instance().
          setState({ page: DECISION_PAGE });
        wrapper.update();
      });

      it('shows cancel model', () => {
        expect(wrapper.find('.cf-modal-body')).toHaveLength(0);

        // click cancel to open modal
        wrapper.find('#button-Cancel').simulate('click');
        expect(wrapper.find('.cf-modal-body')).toHaveLength(1);

        // Click go back and close modal
        findElementById(wrapper, 'Stop-Processing-Claim-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal-body')).toHaveLength(0);
      });
    });

    describe('EstablishClaimNote', () => {
      beforeEach((done) => {
        store.dispatch({
          type: Constants.CHANGE_SPECIAL_ISSUE,
          payload: {
            specialIssue: 'mustardGas',
            value: true
          }
        });
        // wrapper.setState({ reviewForm: { decisionType: { value: 'Full Grant' } } });
        wrapper.
          find('EstablishClaim').
          instance().
          setState({ page: NOTE_PAGE }, () => {
            setImmediate(() => {
              wrapper.update();
              done();
            });
          });
      });

      it('route claim button is disabled until checkbox is checked', () => {
        // button is disabled
        expect(wrapper.find('.usa-button-disabled')).toHaveLength(1);

        // click checkbox
        wrapper.find('#confirmNote').simulate('change', { target: { checked: true } });

        // Ensure that state has had a chance to update
        setImmediate(() => {
          wrapper.update();

          // button is enabled
          expect(wrapper.find('.usa-button-primary')).toHaveLength(1);
        });
      });
    });
  });

  describe('.getClaimTypeFromDecision', () => {
    let task;

    const mountApp = (decisionType, stationOfJurisdiction = '397') => {
      task.appeal.dispatch_decision_type = decisionType;

      const { initialState, reducer } = bootstrapRedux();
      const newStore = createStore(reducer, initialState);

      const wrapper = mount(
        <EstablishClaim
          regionalOfficeCities={{}}
          pdfLink=""
          pdfjsLink=""
          handleAlert={func}
          handleAlertClear={func}
          task={task}
        />,
        {
          wrappingComponent: WrappingComponent,
          wrappingComponentProps: { store: newStore }
        }
      );

      if (stationOfJurisdiction !== '397') {
        newStore.dispatch({
          type: Constants.CHANGE_SPECIAL_ISSUE,
          payload: {
            specialIssue: 'mustardGas',
            value: true
          }
        });
      }

      newStore.dispatch({
        type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
        payload: {
          field: 'stationOfJurisdiction',
          value: stationOfJurisdiction
        }
      });

      return wrapper;
    };

    beforeEach(() => {
      /* eslint-disable camelcase */
      task = {
        appeal: {
          vbms_id: '516517691',
          dispatch_decision_type: 'Remand',
          decisions: [
            {
              label: null
            }
          ],
          non_canceled_end_products_within_30_days: [],
          pending_eps: []
        },
        user: 'a'
      };
      /* eslint-enable camelcase */
    });

    describe('when ARC EP', () => {
      it('returns proper values for remand', () => {
        const wrapper = mountApp('Remand');

        expect(
          wrapper.
            find('EstablishClaim').
            instance().
            getClaimTypeFromDecision()
        ).toEqual(['070RMNDARC', 'ARC Remand (070)']);
      });

      it('returns proper values for partial grant', () => {
        const wrapper = mountApp('Partial Grant');

        expect(
          wrapper.
            find('EstablishClaim').
            instance().
            getClaimTypeFromDecision()
        ).toEqual(['070RMBVAGARC', 'ARC Remand with BVA Grant']);
      });

      it('returns proper values for full grant', () => {
        const wrapper = mountApp('Full Grant');

        expect(
          wrapper.
            find('EstablishClaim').
            instance().
            getClaimTypeFromDecision()
        ).toEqual(['070BVAGRARC', 'ARC BVA Grant']);
      });
    });

    describe('when Routed EP', () => {
      it('returns proper value for remand', () => {
        const wrapper = mountApp('Remand', '301');

        expect(
          wrapper.
            find('EstablishClaim').
            instance().
            getClaimTypeFromDecision()
        ).toEqual(['070RMND', 'Remand (070)']);
      });

      it('returns proper value for partial grant', () => {
        const wrapper = mountApp('Partial Grant', '301');

        expect(
          wrapper.
            find('EstablishClaim').
            instance().
            getClaimTypeFromDecision()
        ).toEqual(['070RMNDBVAG', 'Remand with BVA Grant (070)']);
      });

      it('returns proper value for full grant', () => {
        const wrapper = mountApp('Full Grant', '301');

        expect(
          wrapper.
            find('EstablishClaim').
            instance().
            getClaimTypeFromDecision()
        ).toEqual(['070BVAGR', 'BVA Grant (070)']);
      });
    });
  });
});
