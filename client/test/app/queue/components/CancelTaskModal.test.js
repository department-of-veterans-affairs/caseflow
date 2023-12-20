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
  clickSubmissionButton,
  createSpyRequestPatch
} from './modalUtils';
import CancelTaskModal from 'app/queue/components/CancelTaskModal';
import {
  rpoToBvaIntakeData,
  vhaPOToCAMOData,
  visnData,
  postData
} from '../../../data/queue/taskActionModals/taskActionModalData';

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
  requestPatchSpy = createSpyRequestPatch(postData);
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('Whenever VHA PO returns an appeal to CAMO Team', () => {
  const taskType = 'AssessDocumentationTask';
  const instructionsLabelText = COPY.VHA_CANCEL_TASK_INSTRUCTIONS_LABEL;
  const buttonText = COPY.MODAL_RETURN_BUTTON;
  const additionalContextText = 'This appeal has been sent to the wrong program office. Please review.';

  test('Submission button has correct CSS class', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value, vhaPOToCAMOData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });

  test('Modal has the correct informational text', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value, vhaPOToCAMOData, taskType);

    expect(screen.getByRole('textbox', { name: instructionsLabelText })).toBeTruthy();
  });

  test('Button Disabled until text field is populated', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value, vhaPOToCAMOData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(instructionsLabelText, additionalContextText);

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Resultant case timeline entry labels reason for cancellation', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value, vhaPOToCAMOData, taskType);

    enterTextFieldOptions(instructionsLabelText, additionalContextText);

    clickSubmissionButton(buttonText);

    expect(getReceivedInstructions()).toBe(
      `##### REASON FOR RETURN:\n${additionalContextText}`
    );
  });
});

describe('Whenever RPO returns an appeal to EMO', () => {
  const taskType = 'EducationAssessDocumentationTask';
  const buttonText = COPY.MODAL_RETURN_BUTTON;
  const additionalContextText = 'This appeal has been sent to the wrong RPO. Please review.';

  test('Submission button has correct CSS class', () => {
    renderCancelTaskModal(TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.value, rpoToBvaIntakeData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });

  test('Button Disabled until text field is populated', () => {
    renderCancelTaskModal(TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.value, rpoToBvaIntakeData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL, additionalContextText);

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Resultant case timeline entry labels reason for cancellation', () => {
    renderCancelTaskModal(TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.value, rpoToBvaIntakeData, taskType);

    enterTextFieldOptions(COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL, additionalContextText);

    clickSubmissionButton(buttonText);

    expect(getReceivedInstructions()).toBe(
      `##### REASON FOR CANCELLATION:\n${additionalContextText}`
    );
  });
});

describe('Whenever VISN user returns an appeal to Program Office', () => {
  const taskType = 'AssessDocumentationTask';
  const instructionsLabelText = COPY.VHA_CANCEL_TASK_INSTRUCTIONS_LABEL;
  const buttonText = COPY.MODAL_RETURN_BUTTON;
  const additionalContextText = 'This appeal has been sent to the wrong program office. Please review.';

  test('Submission button has correct CSS class', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE.value, visnData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });

  test('Modal has the correct informational text', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE.value, visnData, taskType);

    expect(screen.getByRole('textbox', { name: instructionsLabelText })).toBeTruthy();
  });

  test('Button Disabled until text field is populated', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE.value, visnData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(instructionsLabelText, additionalContextText);

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Resultant case timeline entry labels reason for cancellation', () => {
    renderCancelTaskModal(TASK_ACTIONS.VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE.value, visnData, taskType);

    enterTextFieldOptions(instructionsLabelText, additionalContextText);

    clickSubmissionButton(buttonText);

    expect(getReceivedInstructions()).toBe(
      `##### REASON FOR RETURN:\n${additionalContextText}`
    );
  });
});

test('Snapshot Matches', () => {
  expect(CancelTaskModal).toMatchSnapshot();
});

