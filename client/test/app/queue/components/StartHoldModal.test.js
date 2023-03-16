import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import COPY from '../../../../COPY';
import TASK_ACTIONS from '../../../../constants/TASK_ACTIONS';
import {
  createQueueReducer,
  getAppealId,
  getTaskId,
  enterTextFieldOptions,
  selectFromDropdown,
  selectCustomDays
} from './modalUtils';
import StartHoldModal from 'app/queue/components/StartHoldModal';
import {
  vhaPOToCAMOData
} from '../../../data/queue/taskActionModals/taskActionModalData';

const renderStartHoldModal = (modalType, storeValues, taskType) => {
  const appealId = getAppealId(storeValues);
  const taskId = getTaskId(storeValues, taskType);

  const queueReducer = createQueueReducer(storeValues);
  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  const path = `/queue/appeals/${appealId}/tasks/${taskId}/modal/${modalType}`;

  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Route component={(props) => {
          return <StartHoldModal {...props.match.params} modalType={modalType} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

describe('Whenever VHA PO places a task on hold for set number of days', () => {
  const taskType = 'AssessDocumentationTask';

  test('Before 15 or 30 days is selected, button should be disabled', () => {
    renderStartHoldModal(TASK_ACTIONS.TOGGLE_TIMED_HOLD.value, vhaPOToCAMOData, taskType);

    expect(screen.getByRole('button', { name: COPY.MODAL_PUT_TASK_ON_HOLD_BUTTON })).toBeDisabled();
  });

  test('Button should still be disabled after days selected but before text box is populated', async () => {
    renderStartHoldModal(TASK_ACTIONS.TOGGLE_TIMED_HOLD.value, vhaPOToCAMOData, taskType);

    selectFromDropdown(
      'Select number of days',
      '15 days'
    );

    expect(screen.getByRole('button', { name: COPY.MODAL_PUT_TASK_ON_HOLD_BUTTON })).toBeDisabled();

    enterTextFieldOptions(
      'Notes',
      'Here is the context that you have requested.'
    );
    expect(screen.getByRole('button', { name: COPY.MODAL_PUT_TASK_ON_HOLD_BUTTON })).not.toBeDisabled();
  });
});

describe('Whenever VHA PO places a task on hold for custom number of days', () => {
  const taskType = 'AssessDocumentationTask';

  test('Before custom number of days is selected, button should be disabled', () => {
    renderStartHoldModal(TASK_ACTIONS.TOGGLE_TIMED_HOLD.value, vhaPOToCAMOData, taskType);

    expect(screen.getByRole('button', { name: COPY.MODAL_PUT_TASK_ON_HOLD_BUTTON })).toBeDisabled();

  });

  test('Button should still be disabled after days selected but before text box is populated', async () => {
    renderStartHoldModal(TASK_ACTIONS.TOGGLE_TIMED_HOLD.value, vhaPOToCAMOData, taskType);

    selectFromDropdown(
      'Select number of days',
      'Custom'
    );

    expect(screen.getByRole('button', { name: COPY.MODAL_PUT_TASK_ON_HOLD_BUTTON })).toBeDisabled();


    selectCustomDays(
      'Enter a custom number of days for the hold',
      '6'
    );

    expect(screen.getByRole('button', { name: COPY.MODAL_PUT_TASK_ON_HOLD_BUTTON })).toBeDisabled();

    enterTextFieldOptions(
      'Notes',
      'Here is the context that you have requested.'
    );
    expect(screen.getByRole('button', { name: COPY.MODAL_PUT_TASK_ON_HOLD_BUTTON })).not.toBeDisabled();
  });
});
