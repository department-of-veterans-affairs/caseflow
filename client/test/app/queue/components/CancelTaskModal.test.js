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
  clickSubmissionButton
} from './modalUtils';
import CancelTaskModal from 'app/queue/components/CancelTaskModal';
import {
  rpoToBvaIntakeData,
  vhaPOToCAMOData,
  postData
} from '../../../data/queue/taskActionModals/taskActionModalData';
import * as uiActions from 'app/queue/uiReducer/uiActions';

let requestPatchSpy;

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

const getReceivedInstructions = () => requestPatchSpy.mock.calls[0][1].data.task.instructions;

beforeEach(() => {
  requestPatchSpy = jest.spyOn(uiActions, 'requestPatch').
    mockImplementation(() => jest.fn(() => Promise.resolve({
      body: {
        ...postData
      }
    })));
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('Whenever VHA PO returns an appeal to CAMO Team', () => {
  const taskType = 'AssessDocumentationTask';
  const buttonText = COPY.MODAL_SUBMIT_BUTTON;
  const additionalContextText = 'This appeal has been sent to the wrong program office. Please review.';

  test('Button Disabled until text field is populated', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value, vhaPOToCAMOData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      additionalContextText
    );

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Resultant case timeline entry labels reason for cancellation', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value, vhaPOToCAMOData, taskType);

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      additionalContextText
    );

    clickSubmissionButton(buttonText);

    expect(getReceivedInstructions()).toBe(
      `**Reason for cancellation:**\n${additionalContextText}`
    );
  });
});

describe('Whenever RPO returns an appeal to EMO', () => {
  const taskType = 'EducationAssessDocumentationTask';
  const buttonText = COPY.MODAL_RETURN_BUTTON;
  const additionalContextText = 'This appeal has been sent to the wrong RPO. Please review.';

  test('Button Disabled until text field is populated', () => {
    renderCancelTaskModal(TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.value, rpoToBvaIntakeData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      additionalContextText
    );

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Resultant case timeline entry labels reason for cancellation', () => {
    renderCancelTaskModal(TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.value, rpoToBvaIntakeData, taskType);

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      additionalContextText
    );

    clickSubmissionButton(buttonText);

    expect(getReceivedInstructions()).toBe(
      `**Reason for cancellation:**\n${additionalContextText}`
    );
  });
});

test('Snapshot Matches', () => {
  expect(CancelTaskModal).toMatchSnapshot();
});

