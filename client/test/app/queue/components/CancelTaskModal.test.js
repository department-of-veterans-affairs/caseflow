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
  enterTextFieldOptions
 
} from './modalUtils';
import CancelTaskModal from 'app/queue/components/CancelTaskModal';
import {
  rpoToBvaIntakeData,
  vhaPOToCAMOData
} from '../../../data/queue/taskActionModals/taskActionModalData';

const renderCancelTaskModal = (modalType, storeValues, taskType) => {
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
          return <CancelTaskModal {...props.match.params} modalType={modalType} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

describe('Whenever VHA PO returns an appeal to CAMO Team', () => {
  const taskType = 'AssessDocumentationTask';

  test('Button Disabled until text field is populated', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value, vhaPOToCAMOData, taskType);

    expect(screen.getByText(COPY.MODAL_RETURN_BUTTON).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(COPY.MODAL_RETURN_BUTTON).closest('button')).not.toBeDisabled();
  });
});

describe('Whenever RPO returns an appeal to EMO', () => {
  const taskType = 'EducationAssessDocumentationTask';

  test('Button Disabled until text field is populated', () => {
    renderCancelTaskModal(TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.value, rpoToBvaIntakeData, taskType);

    expect(screen.getByText(COPY.MODAL_RETURN_BUTTON).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(COPY.MODAL_RETURN_BUTTON).closest('button')).not.toBeDisabled();
  });
});

test('Snapshot Matches', () => {
  expect(CancelTaskModal).toMatchSnapshot();
});

