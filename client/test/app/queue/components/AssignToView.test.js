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
  selectFromDropdown
} from './modalUtils';
import AssignToView from 'app/queue/AssignToView';
import {
  ReturnToOrgData
} from '../../../data/queue/taskActionModals/taskActionModalData';

const renderAssignToView = (modalType, storeValues, taskType) => {
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
          return <AssignToView {...props.match.params} modalType={modalType} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

describe('Whenever BVA Intake returns an appeal to', () => {
  const taskType = 'PreDocketTask';

  it('VHA CAMO', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAMO.value, ReturnToOrgData, taskType);

    expect(screen.getByText(COPY.MODAL_SUBMIT_BUTTON).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(COPY.MODAL_SUBMIT_BUTTON).closest('button')).not.toBeDisabled();
  });

  it('VHA Caregiver Support Program (CSP)', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAREGIVER.value, ReturnToOrgData, taskType);

    expect(screen.getByText(COPY.MODAL_RETURN_BUTTON).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(COPY.MODAL_RETURN_BUTTON).closest('button')).not.toBeDisabled();
  });

  it('Education Service (EMO)', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.value, ReturnToOrgData, taskType);

    expect(screen.getByText(COPY.MODAL_SUBMIT_BUTTON).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action:',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(COPY.MODAL_SUBMIT_BUTTON).closest('button')).not.toBeDisabled();
  });
});

describe('Whenver the EMO assigns an appeal to a Regional Processing Office', () => {
  const taskType = 'EducationDocumentSearchTask';
  const buttonText = COPY.MODAL_SUBMIT_BUTTON;

  it('placeholder', () => {
    expect(true).toBe(true);
  });
});

describe('Whenever VHA CAMO assigns an appeal to a Program Office', () => {
  const taskType = 'VhaDocumentSearchTask';
  const buttonText = COPY.MODAL_SUBMIT_BUTTON;

  it('placeholder', () => {
    expect(true).toBe(true);
  });
});

describe('Whenever a VHA Program Office assigns an appeal to a VISN/Regional Office', () => {
  const taskType = 'AssessDocumentationTask';
  const buttonText = COPY.MODAL_SUBMIT_BUTTON;

  it('placeholder', () => {
    expect(true).toBe(true);
  });
});
