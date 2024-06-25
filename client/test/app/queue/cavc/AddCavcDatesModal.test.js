import React from 'react';
import moment from 'moment';
import thunk from 'redux-thunk';
import { render, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { screen } from '@testing-library/react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/queue/reducers';
import { queueWrapper } from 'test/data/stores/queueStore';
import { amaAppeal } from 'test/data/appeals';

import AddCavcDatesModal from 'app/queue/cavc/AddCavcDatesModal';
import COPY from 'COPY';

import * as uiActions from 'app/queue/uiReducer/uiActions';
import { Provider } from 'react-redux';

describe('AddCavcDatesModal', () => {
  const appealId = amaAppeal.externalId;
  // Pass in the rootReducer and thunk middleware to createStore
  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));
  const setup = ({ appealId: id, store }) => {
    return render(
      <Provider store={store}>
        <MemoryRouter>
          <AddCavcDatesModal appealId={id} />
        </MemoryRouter>
      </Provider>
    );
  };

  const clickSubmit = (cavcModal) => {
    const submitButton = cavcModal.container.querySelector('button#Add-Court-dates-button-id-1');
    fireEvent.click(submitButton);
};

  it('renders correctly', async () => {
    const store = getStore();
    const cavcModal = setup({ appealId, store });

    expect(cavcModal).toMatchSnapshot();
  });

  it('submits successfully', async () => {
    const store = getStore();
    const cavcModal = setup({ appealId, store });

    jest.spyOn(uiActions, 'requestPatch').mockImplementation(() => async (dispatch) => {
      return Promise.resolve();
    });
    const judgementDate = '2020-03-27'
    const mandateDate = '2019-03-31'
    const instructions = 'test instructions';

    const judgementDateElement = screen.getByLabelText(/What is the Court's judgement date?/i);
    fireEvent.change(judgementDateElement, { target: { value: judgementDate } });

    const mandateDateElement = screen.getByLabelText(/What is the Court's mandate date?/i);
    fireEvent.change(mandateDateElement, { target: { value: mandateDate } });

    const instructionsElement = screen.getByLabelText(/Provide instructions and context for this action/i);
    fireEvent.change(instructionsElement, { target: { value: instructions } });

    clickSubmit(cavcModal)

      await store.dispatch(uiActions.requestPatch(`/appeals/${appealId}/cavc_remand`, {
        data: {
          judgement_date: judgementDate,
          mandate_date: mandateDate,
          remand_appeal_id: appealId,
          instructions,
          source_form: 'add_cavc_dates_modal',
        }
      }, {
        title: COPY.CAVC_REMAND_CREATED_TITLE,
        detail: COPY.CAVC_REMAND_CREATED_DETAIL
      }))

      expect(uiActions.requestPatch).toHaveBeenCalledWith(`/appeals/${appealId}/cavc_remand`, {
        data: {
          judgement_date: judgementDate,
          mandate_date: mandateDate,
          remand_appeal_id: appealId,
          instructions,
          source_form: 'add_cavc_dates_modal',
        }
      }, {
        title: COPY.CAVC_REMAND_CREATED_TITLE,
        detail: COPY.CAVC_REMAND_CREATED_DETAIL
    });
    expect(cavcModal).toMatchSnapshot();
  });

  describe('form validations', () => {
    const errorClass = '.usa-input-error-message';
    const futureDate = moment(new Date().toISOString()).add(2, 'day').format('YYYY-MM-DD');

    const validationErrorShows = (cavcModal, errorMessage) => {
      clickSubmit(cavcModal);
      const errorElement = screen.queryByText(new RegExp(errorMessage, 'i'));
      return errorElement ? true : false;
    };

    describe('judgement date validations', () => {
      const error = COPY.CAVC_JUDGEMENT_DATE_ERROR;

      it('shows error on no selected date', () => {
        const store = getStore();
        const cavcModal = setup({ appealId, store });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('shows error on future date selection', () => {
        const store = getStore();
        const cavcModal = setup({ appealId, store });

        const judgementDateElement = screen.getByLabelText(/What is the Court's judgement date?/i);
        fireEvent.change(judgementDateElement, { target: { value: futureDate } });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const store = getStore();
        const cavcModal = setup({ appealId, store });


        const judgementDateElement = screen.getByLabelText(/What is the Court's judgement date?/i);
        fireEvent.change(judgementDateElement, { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });

    describe('mandate date validations', () => {
      const error = COPY.CAVC_MANDATE_DATE_ERROR;

      it('shows error on no selected date', () => {
        const store = getStore();
        const cavcModal = setup({ appealId, store });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('shows error on future date selection', () => {
        const store = getStore();
        const cavcModal = setup({ appealId, store });

        const mandateDateElement = screen.getByLabelText(/What is the Court's mandate date?/i);
        fireEvent.change(mandateDateElement, { target: { value: futureDate } });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const store = getStore();
        const cavcModal = setup({ appealId, store });

        const mandateDateElement = screen.getByLabelText(/What is the Court's mandate date?/i);
        fireEvent.change(mandateDateElement, { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });

    describe('cavc dates instructions validations', () => {
      const error = COPY.CAVC_INSTRUCTIONS_ERROR;

      it('shows error on empty instructions', () => {
        const store = getStore();
        const cavcModal = setup({ appealId, store });

        const instructionsElement = screen.getByLabelText(/Provide instructions and context for this action/i);
        fireEvent.change(instructionsElement, { target: { value: '' } });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on instructions', () => {
        const store = getStore();
        const cavcModal = setup({ appealId, store });

        const instructionsElement = screen.getByLabelText(/Provide instructions and context for this action/i);
        fireEvent.change(instructionsElement, { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });
  });
});
