import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import CreateMailTaskDialog from '../../../../app/queue/CreateMailTaskDialog';
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

const renderCreateMailTaskDialog = (storeValues, taskType) => {
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
          return <CreateMailTaskDialog {...props.match.params} />;
        }} path="/queue/appeals/:appealId/tasks/:taskId/modal/create_mail_task" />
      </MemoryRouter>
    </Provider>
  );
};

describe('CreateMailTaskDialog', () => {
  const setUpMailTaskDialog = () => renderCreateMailTaskDialog(rootTaskData, 'RootTask');

  describe('on modal open', () => {
    const modalTitle = 'Create new mail task';

    test('modal title: "Create new mail task"', () => {
      setUpMailTaskDialog();

      expect(screen.getByText(modalTitle)).toBeTruthy();
    });

    test('submit button is initially disabled', () => {
      setUpMailTaskDialog();

      expect(screen.getByText('Submit')).toBeDisabled();
    });
  });

  describe('after selecting Hearing Postponement Request', () => {
    const label = 'Include eFolder document hyperlink to request a hearing postponement';
    const validInput = 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov/file/12345678-1234-1234-1234-twelvetwelve';
    const instructionsLabel = 'Provide instructions and context for this action';

    test('efolder url link field is present', () => {
      setUpMailTaskDialog();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');

      expect(screen.getByLabelText(label)).toBeTruthy();
    });

    test('instructions field is present', () => {
      setUpMailTaskDialog();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');

      expect(screen.getByLabelText(instructionsLabel)).toBeTruthy();
    });

    test('efolder url link field displays error with invalid link format', async () => {
      jest.useFakeTimers('modern');
      setUpMailTaskDialog();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(label), 'asdf');

      expect(await screen.findByText(COPY.EFOLDER_INVALID_LINK_FORMAT)).toBeInTheDocument();
    });

    test('efolder url link field displays error with vbms when appropriate', async () => {
      jest.useFakeTimers('modern');
      setUpMailTaskDialog();

      const response = { status: 500, statusText: 'Error', ok: false };

      ApiUtil.get.mockResolvedValue(response);

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(label), validInput);

      expect(await screen.findByText(COPY.EFOLDER_CONNECTION_ERROR)).toBeInTheDocument();
      expect(await screen.findByText('Retry')).toBeInTheDocument();
    });

    test('document not found message appears when no document exists', async () => {
      jest.useFakeTimers('modern');
      setUpMailTaskDialog();

      const response = { status: 200, body: { document_presence: false } };

      ApiUtil.get.mockResolvedValue(response);

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(instructionsLabel), 'test instructions');
      userEvent.type(screen.getByLabelText(label), validInput);

      expect(await screen.findByText(COPY.EFOLDER_DOCUMENT_NOT_FOUND)).toBeInTheDocument();
    });

    test('submit button becomes enabled when required fields are complete', async () => {
      jest.useFakeTimers('modern');
      setUpMailTaskDialog();

      const response = { status: 200, body: { document_presence: true } };

      ApiUtil.get.mockResolvedValue(response);

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(instructionsLabel), 'test instructions');
      userEvent.type(screen.getByLabelText(label), validInput);

      expect(await screen.findByText('Submit')).toBeEnabled();
    });
  });
});
