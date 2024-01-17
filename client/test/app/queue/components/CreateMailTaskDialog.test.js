import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen, act } from '@testing-library/react';
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
    const instructionsLabel = 'Provide instructions and context for this action';

    test('instructions field is present', () => {
      setUpMailTaskDialog();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');

      expect(screen.getByLabelText(instructionsLabel)).toBeTruthy();
    });

    test('submit button becomes enabled when required fields are complete', async () => {
      jest.useFakeTimers('modern');
      setUpMailTaskDialog();

      const response = { status: 200, body: { document_presence: true } };

      ApiUtil.get.mockResolvedValue(response);

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');
      userEvent.type(screen.getByLabelText(instructionsLabel), 'test instructions');

      // wait for debounce to finish, which triggers re-render
      await act(async() => jest.runAllTimers());
      // wait for second debounce to get to "same value" guard clause
      jest.runAllTimers();

      expect(await screen.findByText('Submit')).toBeEnabled();
    });
  });
});
