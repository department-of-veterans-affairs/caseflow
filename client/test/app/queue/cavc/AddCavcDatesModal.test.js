import React from 'react';
// import { mount } from 'enzyme';
import moment from 'moment';
import thunk from 'redux-thunk';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { userEvent } from '@testing-library/user-event';
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
      </Provider>,
      {
        wrappingComponent: queueWrapper,
      }
    );
  };
  // const clickSubmit = (cavcModal) => cavcModal.find('button#Add-Court-dates-button-id-1').simulate('click');
  // const clickSubmit = (cavcModal) => {
  //   const submitButton = cavcModal.getByRole('button', { name: 'Submit' });
  //   // console.log('Submit button:', submitButton);
  //   fireEvent.click(submitButton);
  //   // console.log('Button clicked!');
  // };
  const clickSubmit = (cavcModal) => {
    const submitButton = cavcModal.container.querySelector('button#Add-Court-dates-button-id-1');
    // console.log(submitButton)
    fireEvent.click(submitButton);
};

  it('renders correctly', async () => {
    const store = getStore();
    const cavcModal = setup({ appealId, store });

    expect(cavcModal).toMatchSnapshot();
  });

  it.only('submits successfully', async () => {
    const store = getStore();
    const cavcModal = setup({ appealId, store });
    const { getByLabelText, getByRole } = cavcModal;
    // jest.spyOn(uiActions, 'requestPatch').mockImplementation(() => new Promise((resolve) => resolve()));
    jest.spyOn(uiActions, 'requestPatch').mockResolvedValue();
    console.log('requestPatch mocked');

    const judgementDate = '03/27/2020';
    const mandateDate = '03/31/2019';
    const instructions = 'test instructions';

    // fireEvent.change(getByLabelText(/judgement date/i), { target: { value: judgementDate } });
    // console.log("HELLLLLLLLOOOOO",getByLabelText(/judgement date/i).value);
    const input = screen.getByLabelText("What is the Court's judgement date?");
    console.log(input)
    userEvent.click(input);
    userEvent.keyboard(judgementDate);
    // fireEvent.change(input, { target: { value: judgementDate } });
    expect(input.value).toBe(judgementDate);

    // const input = cavcModal.getByLabelText(/What is the Court's judgement date?/i);

    fireEvent.change(getByLabelText(/mandate date/i), { target: { value: mandateDate } });
    fireEvent.change(getByLabelText(/Provide instructions and context for this action/i), { target: { value: instructions } });

    clickSubmit(cavcModal)
    console.log(uiActions.requestPatch.mock.calls);

    // Wait for async actions to complete
    await waitFor(() => {
      // console.log('Waiting for requestPatch to be called');
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
    });
    // console.log('requestPatch was called with the expected arguments');
    expect(cavcModal).toMatchSnapshot();
  });

  describe('form validations', () => {
    const errorClass = '.usa-input-error-message';
    const futureDate = moment(new Date().toISOString()).add(2, 'day').format('YYYY-MM-DD');

    const validationErrorShows = (cavcModal, errorMessage) => {
      clickSubmit(cavcModal);

      return cavcModal.find(errorClass).findWhere((node) => node.props().children === errorMessage).length > 0;
    };

    describe('judgement date validations', () => {
      const error = COPY.CAVC_JUDGEMENT_DATE_ERROR;

      it('shows error on no selected date', () => {
        const cavcModal = setup({ appealId });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('shows error on future date selection', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#judgement-date').simulate('change', { target: { value: futureDate } });
        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#judgement-date').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });

    describe('mandate date validations', () => {
      const error = COPY.CAVC_MANDATE_DATE_ERROR;

      it('shows error on no selected date', () => {
        const cavcModal = setup({ appealId });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('shows error on future date selection', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#mandate-date').simulate('change', { target: { value: futureDate } });
        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#mandate-date').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });

    describe('cavc dates instructions validations', () => {
      const error = COPY.CAVC_INSTRUCTIONS_ERROR;

      it('shows error on empty instructions', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#context-and-instructions-textBox').simulate('change', { target: { value: '' } });

        expect(validationErrorShows(cavcModal, error)).toBeTruthy();
      });

      it('does not show error on instructions', () => {
        const cavcModal = setup({ appealId });

        cavcModal.find('#context-and-instructions-textBox').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcModal, error)).toBeFalsy();
      });
    });
  });
});
