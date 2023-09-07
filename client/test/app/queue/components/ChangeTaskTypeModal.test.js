import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen, act } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import ChangeTaskTypeModal from '../../../../app/queue/ChangeTaskTypeModal';
import {
  createQueueReducer,
  getAppealId,
  getTaskId
} from './modalUtils';
import { rootTaskData } from '../../../data/queue/taskActionModals/taskActionModalData';
import userEvent from '@testing-library/user-event';
import COPY from '../../../../COPY';
import ApiUtil from '../../../../app/util/ApiUtil';
jest.mock('../../../../app/util/ApiUtil');

const renderChangeTaskTypeModal = (storeValues, taskType) => {
  const appealId = getAppealId(storeValues);
  const taskId = getTaskId(storeValues, taskType);

  const queueReducer = createQueueReducer(storeValues);
  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  const path = `/queue/appeals/${appealId}/tasks/${taskId}/modal/create_mail_task`;

  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Route component={(props) => {
          return <ChangeTaskTypeModal {...props.match.params} />;
        }} path="/queue/appeals/:appealId/tasks/:taskId/modal/create_mail_task" />
      </MemoryRouter>
    </Provider>
  );
};

describe('ChangeTaskTypeModal', () => {
  const setUpModal = () => renderChangeTaskTypeModal(rootTaskData, 'RootTask');

  describe('on modal open', () => {
    test('modal title: "Change task type"', () => {
      setUpModal();

      expect(screen.getByRole('heading', { level: 1 })).toBeTruthy();
    });

    test('submit button is initially disabled', () => {
      setUpModal();

      expect(screen.getByText('Change task type', { selector: 'button' })).toBeDisabled();
    });
  });

  describe('after selecting Hearing Postponement Request', () => {
    const label = 'Include eFolder document hyperlink to request a hearing postponement';
    const validInput = 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov/pdf/12345678-1234-1234-1234-twelvetwelve';
    const instructionsLabel = 'Provide instructions and context for this change:';

    test('efolder url link field is present', () => {
      setUpModal();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');

      expect(screen.getByLabelText(label)).toBeTruthy();
    });

    test('instructions field is present', () => {
      setUpModal();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');

      expect(screen.getByLabelText(instructionsLabel)).toBeTruthy();
    });

    test('efolder url link field displays error with invalid link format', async () => {
      jest.useFakeTimers('modern');
      setUpModal();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(label), 'asdf');

      expect(await screen.findByText(COPY.EFOLDER_INVALID_LINK_FORMAT)).toBeInTheDocument();
    });

    test('efolder url link field displays error with vbms when appropriate', async () => {
      jest.useFakeTimers('modern');
      setUpModal();

      const response = { status: 500, statusText: 'Error', ok: false };

      ApiUtil.get.mockResolvedValue(response);

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(label), validInput);

      expect(await screen.findByText(COPY.EFOLDER_CONNECTION_ERROR)).toBeInTheDocument();
      expect(await screen.findByText('Retry')).toBeInTheDocument();
    });

    test('document not found message appears when no document exists', async () => {
      jest.useFakeTimers('modern');
      setUpModal();

      const response = { status: 200, body: { document_presence: false } };

      ApiUtil.get.mockResolvedValue(response);

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(instructionsLabel), 'test instructions');
      userEvent.type(screen.getByLabelText(label), validInput);

      expect(await screen.findByText(COPY.EFOLDER_DOCUMENT_NOT_FOUND)).toBeInTheDocument();
    });

    test('submit button becomes enabled when required fields are complete', async () => {
      jest.useFakeTimers('modern');
      setUpModal();

      const response = { status: 200, body: { document_presence: true } };

      ApiUtil.get.mockResolvedValue(response);

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(instructionsLabel), 'test instructions');
      userEvent.type(screen.getByLabelText(label), validInput);

      // wait for debounce to finish, which triggers re-render
      await act(async() => jest.runAllTimers());
      // wait for second debounce to get to "same value" guard clause
      jest.runAllTimers();

      expect(await screen.findByText('Change task type', { selector: 'button' })).toBeEnabled();
    });

    test('submit button becomes disabled after changing and already valid input', async () => {
      jest.useFakeTimers('modern');
      setUpModal();

      const response = { status: 200, body: { document_presence: true } };

      ApiUtil.get.mockResolvedValue(response);

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(instructionsLabel), 'test instructions');
      userEvent.type(screen.getByLabelText(label), validInput);

      // wait for debounce to finish, which triggers re-render
      await act(async() => jest.runAllTimers());
      // wait for second debounce to get to "same value" guard clause
      jest.runAllTimers();

      expect(await screen.findByText('Change task type', { selector: 'button' })).toBeEnabled();

      userEvent.type(screen.getByLabelText(label), 'a{backspace}');

      expect(await screen.findByText('Change task type', { selector: 'button' })).toBeDisabled();

      // wait for debounce to finish, which triggers re-render
      await act(async() => jest.runAllTimers());
      // wait for second debounce to get to "same value" guard clause
      jest.runAllTimers();

      expect(await screen.findByText('Change task type', { selector: 'button' })).toBeEnabled();
    });
  });
});
