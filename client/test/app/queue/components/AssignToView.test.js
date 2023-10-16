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
  enterModalRadioOptions,
  enterTextFieldOptions,
  selectFromDropdown
} from './modalUtils';
import AssignToView from 'app/queue/AssignToView';
import {
  returnToOrgData,
  emoToBvaIntakeData,
  camoToProgramOfficeToCamoData,
  vhaPOToCAMOData
} from '../../../data/queue/taskActionModals/taskActionModalData';
import userEvent from '@testing-library/user-event';


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
          return <AssignToView {...props.match.params} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

describe('Whenever BVA Intake returns an appeal to', () => {
  const taskType = 'PreDocketTask';
  const buttonText = COPY.MODAL_RETURN_BUTTON;

  test('Submission button for BVA Intake to VHA CAMO has correct CSS class', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAMO.value, returnToOrgData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });

  it('VHA CAMO', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAMO.value, returnToOrgData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Submission button for BVA Intake to VHA CSP has correct CSS class', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAREGIVER.value, returnToOrgData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });

  it('VHA Caregiver Support Program (CSP)', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAREGIVER.value, returnToOrgData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Submission button for BVA Intake to EMO has correct CSS class', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.value, returnToOrgData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });

  it('Education Service (EMO)', () => {
    renderAssignToView(TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.value, returnToOrgData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });
});

describe('Whenever the EMO assigns an appeal to a Regional Processing Office', () => {
  const taskType = 'EducationDocumentSearchTask';
  const buttonText = COPY.MODAL_ASSIGN_BUTTON;

  it('Button Disabled until a RPO is chosen from the dropdown', () => {
    renderAssignToView(TASK_ACTIONS.EMO_ASSIGN_TO_RPO.value, emoToBvaIntakeData, taskType);
    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    selectFromDropdown(
      'Assign to selector',
      'Buffalo RPO'
    );

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Submission button has correct CSS class', () => {
    renderAssignToView(TASK_ACTIONS.EMO_ASSIGN_TO_RPO.value, emoToBvaIntakeData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });
});

describe('Whenever VHA CAMO assigns an appeal to a Program Office', () => {
  const taskType = 'VhaDocumentSearchTask';
  const buttonText = COPY.MODAL_ASSIGN_BUTTON;

  it('Submission button is disabled until dropdown and text fields are populated', () => {
    renderAssignToView(TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.value, camoToProgramOfficeToCamoData, taskType);
    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    selectFromDropdown(
      'Assign to selector',
      'Prosthetics'
    );

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    enterTextFieldOptions(
      'Provide instructions and context for this action',
      'Here is the context that you have requested.'
    );

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  test('Submission button has correct CSS class', () => {
    renderAssignToView(TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.value, camoToProgramOfficeToCamoData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });
});

describe('Whenever a VHA Program Office assigns an appeal to a VISN/Regional Office', () => {
  const taskType = 'AssessDocumentationTask';
  const buttonText = COPY.MODAL_ASSIGN_BUTTON;

  it('Submission button is disabled until dropdown and text fields are populated', () => {
    renderAssignToView(TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.value, vhaPOToCAMOData, taskType);

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    userEvent.click(
      screen.getByRole('radio', { name: 'VISN' })
    );

    expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

    selectFromDropdown(
      'VISN',
      'VISN 21 - Sierra Pacific Network'
    );

    expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();
  });

  it('displays visn if a vamc is selected', () => {
    renderAssignToView(TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.value, vhaPOToCAMOData, taskType);

    userEvent.click(
      screen.getByRole('radio', { name: 'VA Medical Center' })
    );

    selectFromDropdown(
      'VA Medical Center',
      'South Texas Veterans Health Care System'
    );

    expect(screen.getByText('VISN 17 - VA Heart of Texas Health Care Network')).toBeInTheDocument();
  });

  test('Submission button has correct CSS class', () => {
    renderAssignToView(TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.value, vhaPOToCAMOData, taskType);

    const submissionButton = screen.getByText(buttonText).closest('button');

    expect(submissionButton).toHaveClass('usa-button');
    expect(submissionButton).not.toHaveClass('usa-button-secondary');
  });
});
