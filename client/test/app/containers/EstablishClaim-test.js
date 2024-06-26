import React from 'react';
import { logRoles, render, screen, fireEvent, waitFor } from '@testing-library/react';
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
import { log } from 'console';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('app/util/ApiUtil', () => ({
  convertToSnakeCase: jest.fn(obj => obj),
  put: jest.fn().mockResolvedValue({}),
}));

let func = function() {
  // empty function
};

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

const regionalOfficeCities = {
  RO11: {
    city: 'Pittsburgh',
    state: 'PA',
    timezone: 'America/New_York'
  }
};

describe('EstablishClaim', () => {
  const setup = (props = {}, page) => {
    return render(
      <EstablishClaim
        regionalOfficeCities={regionalOfficeCities}
        pdfLink=""
        pdfjsLink=""
        handleAlert={func}
        handleAlertClear={func}
        task={task}
        page={page}
        {...props}
      />,
      {
        wrapper: WrappingComponent
      }
    );
  };

  describe('.render', () => {


    describe('EstablishClaimForm', () => {
      beforeEach(() => {
        store.dispatch({
          type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
          payload: {
            field: 'stationOfJurisdiction',
            value: '397'
          }
        });
      });

      it('shows cancel modal', () => {
        const {container} = setup(FORM_PAGE);

        expect(container.querySelector('.cf-modal')).toBeNull();

        // click cancel to open modal
        const cancelButton = screen.getByRole('button', { name: /Cancel/i });
        fireEvent.click(cancelButton);
        expect(container.querySelector('.cf-modal')).not.toBeNull();

        // Click go back and close modal
        const stopProcessingClaimButton = container.querySelector('#Stop-Processing-Claim-button-id-0');
        fireEvent.click(stopProcessingClaimButton);
        expect(container.querySelector('.cf-modal')).toBeNull();
      });
    });

    describe('EstablishClaimDecision', () => {
      it('shows cancel model', () => {
        const {container} = setup(DECISION_PAGE);

        expect(container.querySelector('.cf-moda-body')).toBeNull();

        // click cancel to open modal
        const cancelButton = screen.getByRole('button', { name: /Cancel/i });
        fireEvent.click(cancelButton);
        expect(container.querySelector('.cf-modal-body')).not.toBeNull();

        const stopProcessingClaimButton = container.querySelector('#Stop-Processing-Claim-button-id-0');
        fireEvent.click(stopProcessingClaimButton);
        expect(container.querySelector('.cf-modal-body')).toBeNull();
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
        done();
      });

      it('route claim button is disabled until checkbox is checked', async () => {
        const {container} = setup({}, NOTE_PAGE);

        const cancelButton = screen.getByRole('button', { name: /Cancel/i });
        fireEvent.click(cancelButton);

        // logRoles(container);

        // Ensure the button is initially disabled
        // const button = getByText(/Finish routing claim/i);
        // expect(button).toBeDisabled();

        // Simulate clicking the checkbox
        // const checkbox = getByLabelText(/Confirm Note/i);
        // fireEvent.click(checkbox);

        // Wait for the button to be enabled
        // await waitFor(() => {
        //   expect(button).not.toBeDisabled();
        // });
      });
    });
  });

  describe('.getClaimTypeFromDecision', () => {

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
      pending_eps: []
    },
    user: 'a'
  };

    const mountApp = (decisionType, stationOfJurisdiction = '397') => {
      task.appeal.dispatch_decision_type = decisionType;

      const { initialState, reducer } = bootstrapRedux();
      const newStore = createStore(reducer, initialState);

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

      const props = {
        regionalOfficeCities: {},
        pdfLink: "",
        pdfjsLink: "",
        handleAlert: func,
        handleAlertClear: func,
        task: task,
        page: 'form'
      };

      console.log('Props passed to EstablishClaim:', props);

      return render(
        <EstablishClaim {...props} />,
        {
          wrapper: WrappingComponent,
          wrapperProps: { store: newStore }
        }
      );
    };
    // const mountApp = (
    //   decisionType,
    //   stationOfJurisdiction = '397',
    //   page = 'decision',
    //   additionalProps = {},
    //   additionalState = {}
    // ) => {
    //   task.appeal.dispatch_decision_type = decisionType;

    //   const { initialState, reducer } = bootstrapRedux();

    //   // Merge additional state with initial state
    //   const mergedInitialState = {
    //     ...initialState,
    //     ...additionalState,
    //     page: page // Set the page in the initial state
    //   };

    //   const newStore = createStore(reducer, mergedInitialState);

    //   if (stationOfJurisdiction !== '397') {
    //     newStore.dispatch({
    //       type: Constants.CHANGE_SPECIAL_ISSUE,
    //       payload: {
    //         specialIssue: 'mustardGas',
    //         value: true
    //       }
    //     });
    //   }

    //   newStore.dispatch({
    //     type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
    //     payload: {
    //       field: 'stationOfJurisdiction',
    //       value: stationOfJurisdiction
    //     }
    //   });

    //   const defaultProps = {
    //     regionalOfficeCities: {},
    //     pdfLink: "",
    //     pdfjsLink: "",
    //     handleAlert: jest.fn(),
    //     handleAlertClear: jest.fn(),
    //     task: task,
    //     page: page
    //   };

    //   // Merge additional props with default props
    //   const props = {
    //     ...defaultProps,
    //     ...additionalProps
    //   };

    //   console.log('Props passed to EstablishClaim:', props);

    //   return render(
    //     <EstablishClaim {...props} />,
    //     {
    //       wrapper: ({ children }) => (
    //         <WrappingComponent store={newStore}>
    //           {children}
    //         </WrappingComponent>
    //       )
    //     }
    //   );
    // };

    describe('when ARC EP', () => {
      it.only('changes to form page after decision page submission', async () => {
        // Mock the API call
        ApiUtil.put.mockResolvedValue({});

        // Create a spy for handlePageChange
        // const handlePageChangeSpy = jest.fn();



        // Mock the conditions
        // const willCreateEndProduct = jest.fn().mockReturnValue(true);
        // const shouldShowAssociatePage = jest.fn().mockReturnValue(false);

        // Render the component
        const { container } = mountApp('Remand');


        const checkbox = screen.getByRole('checkbox', { name: /mustardGas/i });
        fireEvent.click(checkbox);
        // const button = screen.getByRole('link', { name: /Route claim/i });
        // fireEvent.click(button);

        // logRoles(container);
        screen.debug(null, Infinity);


        // Get the instance of EstablishClaim
        // const instance = container.querySelector('EstablishClaim').instance();

        // Mock the methods on the instance
        // instance.willCreateEndProduct = willCreateEndProduct;
        // instance.shouldShowAssociatePage = shouldShowAssociatePage;

        // Call handleDecisionPageSubmit
        // await instance.handleDecisionPageSubmit();

        // Assert that handlePageChange was called with FORM_PAGE
        // expect(handlePageChangeSpy).toHaveBeenCalledWith('FORM_PAGE');

        // You might also want to check if the state has been updated correctly
        // expect(instance.state.loading).toBe(false);

        // Additional assertions as needed
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
