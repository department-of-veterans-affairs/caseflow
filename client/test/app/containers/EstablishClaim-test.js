import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import EstablishClaim from '../../../app/containers/EstablishClaimPage/EstablishClaim';
import * as Constants from '../../../app/establishClaim/constants';
import { WrappingComponent, store } from '../establishClaim/WrappingComponent';
import bootstrapRedux from '../../../app/establishClaim/reducers/bootstrap';
import { createStore } from 'redux';

jest.mock('app/util/ApiUtil', () => ({
  convertToSnakeCase: jest.fn(obj => obj),
  put: jest.fn().mockResolvedValue({}),
  post: jest.fn().mockResolvedValue({})
}));

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
  describe('.getClaimTypeFromDecision', () => {

    const setup = ({ props = {}, decisionType, stationOfJurisdiction = '397' } = {}) => {
      const task2 = {
        appeal: {
          vbms_id: '516517691',
          dispatch_decision_type: decisionType,
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

      const utils = render(
        <EstablishClaim
          pdfLink=""
          pdfjsLink=""
          handleAlert={() => {}}
          handleAlertClear={() => {}}
          task={task2}
          {...props}
        />,
        {
          wrapper: ({ children }) => <WrappingComponent store={store}>{children}</WrappingComponent>
        }
      );

      if (stationOfJurisdiction !== '397') {
        store.dispatch({
          type: Constants.CHANGE_SPECIAL_ISSUE,
          payload: {
            specialIssue: 'mustardGas',
            value: true
          }
        });
      }

      store.dispatch({
        type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
        payload: {
          field: 'stationOfJurisdiction',
          value: stationOfJurisdiction
        }
      });

      return utils;
    };

    describe('when ARC EP', () => {
      it('changes to form page after decision page submission', async () => {
        setup({ decisionType: 'Remand' });

        const routeClaimButton = screen.getByRole('link', { name: /Route claim/i });
        await waitFor(() => expect(routeClaimButton).not.toBeDisabled());
        fireEvent.click(routeClaimButton);

        await waitFor(() => {
            const loadingButtonDecision = screen.getByRole('button', { name: /Loading.../i });
            expect(loadingButtonDecision).toHaveClass('cf-submit usa-button-disabled cf-dispatch cf-loading');
            expect(loadingButtonDecision).toBeDisabled();
          });

        const claimLabelValue = screen.getByRole('textbox', { name: /EP & Claim Label/i });
        expect(claimLabelValue).toHaveValue('070RMNDARC - ARC Remand (070)');

        const stationOfJurisdiction = screen.getByRole('textbox', { name: /Station of Jurisdiction/i });
        expect(stationOfJurisdiction).toHaveValue('397 - ARC');
      });

      it('returns proper values for partial grant', async () => {
        setup({ decisionType: 'Partial Grant' });

        const routeClaimButton = screen.getByRole('link', { name: /Route claim/i });
        await waitFor(() => expect(routeClaimButton).not.toBeDisabled());
        fireEvent.click(routeClaimButton);

        await waitFor(() => {
          const loadingButtonDecision = screen.getByRole('button', { name: /Loading.../i });
          expect(loadingButtonDecision).toHaveClass('cf-submit usa-button-disabled cf-dispatch cf-loading');
          expect(loadingButtonDecision).toBeDisabled();
        });

        const claimLabelValue = screen.getByRole('textbox', { name: /EP & Claim Label/i });
        expect(claimLabelValue).toHaveValue('070RMBVAGARC - ARC Remand with BVA Grant');

        const stationOfJurisdiction = screen.getByRole('textbox', { name: /Station of Jurisdiction/i });
        expect(stationOfJurisdiction).toHaveValue('397 - ARC');
      });

      it('returns proper values for full grant', async () => {
        setup({ decisionType: 'Full Grant' });

        const routeClaimButton = screen.getByRole('link', { name: /Route claim/i });
        await waitFor(() => expect(routeClaimButton).not.toBeDisabled());
        fireEvent.click(routeClaimButton);

        await waitFor(() => {
          const loadingButtonDecision = screen.getByRole('button', { name: /Loading.../i });
          expect(loadingButtonDecision).toHaveClass('cf-submit usa-button-disabled cf-dispatch cf-loading');
          expect(loadingButtonDecision).toBeDisabled();
        });

        const claimLabelValue = screen.getByRole('textbox', { name: /EP & Claim Label/i });
        expect(claimLabelValue).toHaveValue('070BVAGRARC - ARC BVA Grant');

        const stationOfJurisdiction = screen.getByRole('textbox', { name: /Station of Jurisdiction/i });
        expect(stationOfJurisdiction).toHaveValue('397 - ARC');
      });
    });

    describe('when Routed EP', () => {
      it('returns proper value for remand', async () => {
        setup({ decisionType: 'Remand', stationOfJurisdiction: '301'});

        const routeClaimButton = screen.getByRole('link', { name: /Route claim/i });
        await waitFor(() => expect(routeClaimButton).not.toBeDisabled());
        fireEvent.click(routeClaimButton);

        await waitFor(() => {
          const loadingButtonDecision = screen.getByRole('button', { name: /Loading.../i });
          expect(loadingButtonDecision).toHaveClass('cf-submit usa-button-disabled cf-dispatch cf-loading');
          expect(loadingButtonDecision).toBeDisabled();
        });

        const claimLabelValue = screen.getByRole('textbox', { name: /EP & Claim Label/i });
        expect(claimLabelValue).toHaveValue('070RMND - Remand (070)');

        const stationOfJurisdiction = screen.getByRole('textbox', { name: /Station of Jurisdiction/i });
        expect(stationOfJurisdiction).toHaveValue('351 - Muskogee, OK');
      });

      it('returns proper value for partial grant', async () => {
        setup({ decisionType: 'Partial Grant', stationOfJurisdiction: '301'});

        const routeClaimButton = screen.getByRole('link', { name: /Route claim/i });
        await waitFor(() => expect(routeClaimButton).not.toBeDisabled());
        fireEvent.click(routeClaimButton);

        await waitFor(() => {
          const loadingButtonDecision = screen.getByRole('button', { name: /Loading.../i });
          expect(loadingButtonDecision).toHaveClass('cf-submit usa-button-disabled cf-dispatch cf-loading');
          expect(loadingButtonDecision).toBeDisabled();
        });

        const claimLabelValue = screen.getByRole('textbox', { name: /EP & Claim Label/i });
        expect(claimLabelValue).toHaveValue('070RMNDBVAG - Remand with BVA Grant (070)');

        const stationOfJurisdiction = screen.getByRole('textbox', { name: /Station of Jurisdiction/i });
        expect(stationOfJurisdiction).toHaveValue('351 - Muskogee, OK');
      });

      it('returns proper value for full grant', async () => {
        setup({ decisionType: 'Full Grant', stationOfJurisdiction: '301'});

        const routeClaimButton = screen.getByRole('link', { name: /Route claim/i });
        await waitFor(() => expect(routeClaimButton).not.toBeDisabled());
        fireEvent.click(routeClaimButton);

        await waitFor(() => {
          const loadingButtonDecision = screen.getByRole('button', { name: /Loading.../i });
          expect(loadingButtonDecision).toHaveClass('cf-submit usa-button-disabled cf-dispatch cf-loading');
          expect(loadingButtonDecision).toBeDisabled();
        });

        const claimLabelValue = screen.getByRole('textbox', { name: /EP & Claim Label/i });
        expect(claimLabelValue).toHaveValue('070BVAGR - BVA Grant (070)');

        const stationOfJurisdiction = screen.getByRole('textbox', { name: /Station of Jurisdiction/i });
        expect(stationOfJurisdiction).toHaveValue('351 - Muskogee, OK');
      });
    });
  });


  describe('.render', () => {
    const setup = (props = {}) => {
      const { initialState, reducer } = bootstrapRedux();
      const store = createStore(reducer, initialState);

      return render(
        <EstablishClaim
          regionalOfficeCities={regionalOfficeCities}
          pdfLink=""
          pdfjsLink=""
          handleAlert={() => {}}
          handleAlertClear={() => {}}
          task={task}
          {...props}
        />,
        {
          wrapper: ({ children }) => <WrappingComponent store={store}>{children}</WrappingComponent>
        }
      );
    };
    describe('EstablishClaimForm', () => {
      it('shows cancel modal', async () => {
        const {container} = setup();

        expect(container.querySelector('.cf-modal')).toBeNull();

        const routeClaimButton = screen.getByRole('link', { name: /Route claim/i });
        fireEvent.click(routeClaimButton);

        // Wait for the page change
        await waitFor(() => {
          const loadingButton = screen.getByRole('button', { name: /Loading.../i });
          expect(loadingButton).toHaveClass('cf-submit usa-button-disabled cf-dispatch cf-loading');
          expect(loadingButton).toBeDisabled();
        });

        // Verify Form Page
        const progressBarActivatedDivs = container.querySelectorAll('.cf-progress-bar-activated');
        let textContents = [];
        progressBarActivatedDivs.forEach(div => {
          textContents.push(div.textContent.trim());
        });
        expect(textContents).toContain('2. Route Claim');

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
        const {container} = setup();

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

    // This test must be last to maintin proper state as there is no way to
    // go back to the decision page from the note page
    describe('EstablishClaimNote', () => {
      it('route claim button is disabled until checkbox is checked', async () => {
        const {container} = setup();

        const mustardGasCheckbox = screen.getByRole('checkbox', { name: /mustardGas/i });
        fireEvent.click(mustardGasCheckbox);
        await waitFor(() => expect(mustardGasCheckbox).toBeChecked());

        const routeClaimButton = screen.getByRole('link', { name: /Route claim/i });
        await waitFor(() => expect(routeClaimButton).not.toBeDisabled());
        fireEvent.click(routeClaimButton);

        await waitFor(() => {
          const loadingButtonDecision = screen.getByRole('button', { name: /Loading.../i });
          expect(loadingButtonDecision).toHaveClass('cf-submit usa-button-disabled cf-dispatch cf-loading');
          expect(loadingButtonDecision).toBeDisabled();
        });

         // Verify Form Page
         const progressBarActivatedDivs = container.querySelectorAll('.cf-progress-bar-activated');
         let textContents = [];
         progressBarActivatedDivs.forEach(div => {
           textContents.push(div.textContent.trim());
         });

        expect(textContents).toContain('2. Route Claim');

        const createEndProductButton = screen.getByRole('button', { name: /Create End Product/i });
        await waitFor(() => expect(createEndProductButton).not.toBeDisabled());
        fireEvent.click(createEndProductButton);

        // Verify Note Page
        await waitFor(() => {
          expect(screen.getByText("I confirm that I have created a VBMS note to help route this claim.")).toBeInTheDocument();
        });

        const finishRoutingClaimButton = screen.getByRole('button', { name: /Finish routing claim/i });
        await waitFor(() => expect(finishRoutingClaimButton).toBeDisabled());

        const confirmNoteCheckbox = screen.getByRole('checkbox', { name: /confirmNote/i });
        fireEvent.click(confirmNoteCheckbox);

        await waitFor(() => expect(finishRoutingClaimButton).not.toBeDisabled());
      });
    });
  });
});
