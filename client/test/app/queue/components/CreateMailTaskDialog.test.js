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

    test('submit button is initially disabled', () =>{
      setUpMailTaskDialog();

      expect(screen.getByText('Submit')).toBeDisabled();
    });
  });

  describe('after selecting Hearing Postponement Request', () => {
    test('efolder url link field is present', () => {
      setUpMailTaskDialog();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');

      expect(screen.getByLabelText('Include Caseflow Reader document hyperlink to request a hearing postponement')).
        toBeTruthy();
    });

    test('instructions field is present', () => {
      setUpMailTaskDialog();

      userEvent.type(screen.getByRole('combobox'), 'Hearing postponement request{enter}');

      expect(screen.getByLabelText('Provide instructions and context for this action')).toBeTruthy();
    });
  });
});
