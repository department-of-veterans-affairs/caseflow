/* eslint-disable max-lines */
import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import COPY from '../../../../COPY';
import {
  createQueueReducer,
  getAppealId,
  getTaskId,
  enterTextFieldOptions,
  enterModalRadioOptions,
  selectFromDropdown,
  clickSubmissionButton
} from './modalUtils';
import {
  postData,
  camoToBvaIntakeData,
  camoToProgramOfficeToCamoData,
  caregiverToIntakeData,
  emoToBvaIntakeData,
  rpoToBvaIntakeData,
  vhaPOToCAMOData,
  visnData
} from '../../../data/queue/taskActionModals/taskActionModalData';
import * as uiActions from 'app/queue/uiReducer/uiActions';
import CompleteTaskModal from 'app/queue/components/CompleteTaskModal';

let requestPatchSpy;

const renderCompleteTaskModal = (modalType, storeValues, taskType) => {
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
          return <CompleteTaskModal {...props.match.params} modalType={modalType} />;
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

describe('CompleteTaskModal', () => {
  describe('vha_send_to_board_intake', () => {
    const taskType = 'VhaDocumentSearchTask';
    const buttonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'vha_send_to_board_intake';

    test('modal title is Send to Board Intake', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByText('Send to Board Intake')).toBeTruthy();
    });

    test('Submission button has correct CSS class', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      const submissionButtonClasses = screen.getByText(buttonText).closest('button').classList;

      expect(submissionButtonClasses.contains('usa-button')).toBe(true);
      expect(submissionButtonClasses.contains('usa-button-secondary')).not.toBe(true);
    });

    test('Before Radio button is Chosen, button should be disabled', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);
      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();
    });

    test('CAMO Notes section only appears once whenever CAMO sends appeal back to BVA Intake', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Correct documents have been successfully added'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_BODY,
        'CAMO -> BVA Intake'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        '\n**Status:**\nCorrect documents have been successfully added\n\n' +
        '**CAMO Notes:**\nCAMO -> BVA Intake'
      );
    });

    test('PO Details appear next to Program Office Notes section', () => {
      renderCompleteTaskModal(modalType, camoToProgramOfficeToCamoData, taskType);

      enterModalRadioOptions(
        'Correct documents have been successfully added'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        COPY.VHA_SEND_TO_BOARD_INTAKE_MODAL_BODY,
        'CAMO -> BVA Intake'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        '\n**Status:**\nCorrect documents have been successfully added\n\n' +
        '**CAMO Notes:**\nCAMO -> BVA Intake\n\n' +
        '**Program Office Notes:**\nDocuments for this appeal are stored in VBMS.\n\n' +
        '**Detail:**\n PO back to CAMO!\n\n'
      );
    });

    test('No errors are thrown if any task in tree has null instructions', () => {

      const taskIDs = Object.keys(camoToProgramOfficeToCamoData.queue.amaTasks);

      const taskDataWithNullInstructions = camoToProgramOfficeToCamoData;

      taskIDs.forEach((id) => {
        if (taskDataWithNullInstructions.queue.amaTasks[id].assignedTo.type !== 'VhaProgramOffice') {
          taskDataWithNullInstructions.queue.amaTasks[id].instructions = null;
        }
      });

      renderCompleteTaskModal(modalType, taskDataWithNullInstructions, taskType);

      enterModalRadioOptions('Correct documents have been successfully added');

      enterTextFieldOptions(
        'Provide additional context and/or documents',
        'Null test'
      );

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        '\n**Status:** Correct documents have been successfully added' +
        '\n\n**CAMO Notes:** Null test\n' +
        '\n**Program Office Notes:** Documents for this appeal are stored in VBMS.' +
        '\n\n**Detail:**' +
        '\n\n PO back to CAMO!\n\n'
      );
    });
  });

  describe('Vha Po send to Vha Camo for review', () => {
    const taskType = 'AssessDocumentationTask';
    const buttonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'ready_for_review';

    test('modal title is Ready for review', () => {
      renderCompleteTaskModal(modalType, vhaPOToCAMOData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('modal text indicates appeal will be sent to VHA CAMO', () => {
      renderCompleteTaskModal(modalType, vhaPOToCAMOData, taskType);
      expect(screen.getByText('This appeal will be sent to VHA CAMO for review.Please select where the documents for this appeal are stored')).toBeTruthy();
    });

    test('Submission button has correct CSS class', () => {
      renderCompleteTaskModal(modalType, vhaPOToCAMOData, taskType);

      const submissionButtonClasses = screen.getByText(buttonText).closest('button').classList;

      expect(submissionButtonClasses.contains('usa-button')).toBe(true);
      expect(submissionButtonClasses.contains('usa-button-secondary')).not.toBe(true);
    });

    test('Before Radio button is Chosen, button should be disabled', () => {
      renderCompleteTaskModal(modalType, vhaPOToCAMOData, taskType);
      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();
    });

    test('When Centralized Mail Portal is chosen in Modal', () => {
      renderCompleteTaskModal(modalType, vhaPOToCAMOData, taskType);

      enterModalRadioOptions(
        'Centralized Mail Portal'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path',
        'VHA PO -> BVA Intake'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Centralized Mail Portal.' +
        '\n\n**Detail:**\nVHA PO -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal(modalType, vhaPOToCAMOData, taskType);

      enterModalRadioOptions(
        'Other'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path',
        'PO -> CAMO'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Please indicate the source',
        'Other Source'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Other Source.' +
        '\n\n**Detail:**\nPO -> CAMO\n'
      );
    });
  });

  describe('Vha Ro send to Vha Po for review', () => {
    const taskType = 'AssessDocumentationTask';
    const buttonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'ready_for_review';

    test('modal title is Ready for review', () => {
      renderCompleteTaskModal(modalType, visnData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('modal text indicates appeal will be sent to VHA Program Office', () => {
      renderCompleteTaskModal(modalType, visnData, taskType);
      expect(screen.getByText('This appeal will be sent to VHA Program Office for review.Please select where the documents for this appeal are stored')).toBeTruthy();
    });

    test('Before Radio button is Chosen, button should be disabled', () => {
      renderCompleteTaskModal(modalType, visnData, taskType);
      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();
    });

    test('When Centralized Mail Portal is chosen in Modal', () => {
      renderCompleteTaskModal(modalType, visnData, taskType);

      enterModalRadioOptions(
        'Centralized Mail Portal'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path',
        'VHA PO -> BVA Intake'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Centralized Mail Portal.' +
        '\n\n**Detail:**\n\nVHA PO -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal(modalType, visnData, taskType);

      enterModalRadioOptions(
        'Other'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path',
        'PO -> CAMO'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Please indicate the source',
        'Other Source'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Other Source.' +
        '\n\n**Detail:**\n\nPO -> CAMO\n'
      );
    });
  });


  describe('vha_caregiver_support_send_to_board_intake_for_review', () => {
    const taskType = 'VhaDocumentSearchTask';
    const buttonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'vha_caregiver_support_send_to_board_intake_for_review';

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('Submission button has correct CSS class', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      const submissionButtonClasses = screen.getByText(buttonText).closest('button').classList;

      expect(submissionButtonClasses.contains('usa-button')).toBe(true);
      expect(submissionButtonClasses.contains('usa-button-secondary')).not.toBe(true);
    });

    test('Before Radio button is Chosen, button should be disabled', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);
      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();
    });

    test('When VBMS is chosen in Modal', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      enterModalRadioOptions(
        'VBMS'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path Optional',
        'CAREGIVER -> BVA Intake'
      );

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in VBMS.' +
        '\n\n**Detail:**\nCAREGIVER -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      enterModalRadioOptions(
        'Other'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path Optional',
        'CAREGIVER -> BVA Intake'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Please indicate the source',
        'Other Source'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Other Source.' +
        '\n\n**Detail:**\nCAREGIVER -> BVA Intake\n'
      );
    });
  });

  describe('emo_send_to_board_intake_for_review', () => {
    const taskType = 'EducationDocumentSearchTask';
    const buttonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'emo_send_to_board_intake_for_review';

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('Submission button has correct CSS class', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);

      const submissionButtonClasses = screen.getByText(buttonText).closest('button').classList;

      expect(submissionButtonClasses.contains('usa-button')).toBe(true);
      expect(submissionButtonClasses.contains('usa-button-secondary')).not.toBe(true);
    });

    test('Before Radio button is Chosen, button should be disabled', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);
      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();
    });

    test('When Centralized Mail Portal is chosen in Modal', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Centralized Mail Portal'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path Optional',
        'EMO -> BVA Intake'
      );

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Centralized Mail Portal.' +
        '\n\n**Detail:**\nEMO -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Other'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path Optional',
        'EMO -> BVA Intake'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Please indicate the source',
        'Other Source'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Other Source.' +
        '\n\n**Detail:**\nEMO -> BVA Intake\n'
      );
    });
  });

  describe('rpo_send_to_board_intake_for_review', () => {
    const taskType = 'EducationAssessDocumentationTask';
    const buttonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'rpo_send_to_board_intake_for_review';

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal(modalType, rpoToBvaIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('Submission button has correct CSS class', () => {
      renderCompleteTaskModal(modalType, rpoToBvaIntakeData, taskType);

      const submissionButtonClasses = screen.getByText(buttonText).closest('button').classList;

      expect(submissionButtonClasses.contains('usa-button')).toBe(true);
      expect(submissionButtonClasses.contains('usa-button-secondary')).not.toBe(true);
    });

    test('Before Radio button is Chosen, button should be disabled', () => {
      renderCompleteTaskModal(modalType, rpoToBvaIntakeData, taskType);
      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();
    });

    test('When Centralized Mail Portal is chosen in Modal', () => {
      renderCompleteTaskModal(modalType, rpoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Centralized Mail Portal'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path Optional',
        'RPO -> BVA Intake'
      );

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Centralized Mail Portal.' +
        '\n\n**Detail:**\nRPO -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal(modalType, rpoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Other'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Provide details such as file structure or file path Optional',
        'RPO -> BVA Intake'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Please indicate the source',
        'Other Source'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Other Source.' +
        '\n\n**Detail:**\nRPO -> BVA Intake\n'
      );
    });
  });

  describe('emo_return_to_board_intake', () => {
    const taskType = 'EducationDocumentSearchTask';
    const buttonText = COPY.MODAL_RETURN_BUTTON;
    const modalType = 'emo_return_to_board_intake';

    test('modal title is Return to Board Intake', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);
      expect(screen.getByText('Return to Board Intake')).toBeTruthy();
    });

    test('Submission button has correct CSS class', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);

      const submissionButtonClasses = screen.getByText(buttonText).closest('button').classList;

      expect(submissionButtonClasses.contains('usa-button')).toBe(true);
      expect(submissionButtonClasses.contains('usa-button-secondary')).not.toBe(true);
    });

    test('When mandatory text box is empty, button should be disabled', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);
      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        COPY.PRE_DOCKET_MODAL_BODY,
        'EMO Return to Board Intake'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        'EMO Return to Board Intake'
      );
    });
  });

  describe('vha_caregiver_support_return_to_board_intake', () => {
    const taskType = 'VhaDocumentSearchTask';
    const buttonText = COPY.MODAL_RETURN_BUTTON;
    const modalType = 'vha_caregiver_support_return_to_board_intake';

    test('Modal title to be "Return to Board Intake"', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);
      expect(screen.getByText('Return to Board Intake')).toBeTruthy();
    });

    test('Submission button has correct CSS class', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      const submissionButtonClasses = screen.getByText(buttonText).closest('button').classList;

      expect(submissionButtonClasses.contains('usa-button')).toBe(true);
      expect(submissionButtonClasses.contains('usa-button-secondary')).not.toBe(true);
    });

    test('Before Radio button is Chosen, button should be disabled', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);
      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();
    });

    test('Instructions are formatted properly whenever a non-other reason is selected for return', async () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      selectFromDropdown(
        'Why is this appeal being returned?',
        'Not PCAFC related'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        '\n**Reason for return:**\nNot PCAFC related'
      );
    });

    test('Instructions are formatted properly whenever a non-other reason and context is provided', async () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      selectFromDropdown(
        'Why is this appeal being returned?',
        'Not PCAFC related'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      enterTextFieldOptions(
        'Provide additional context for this action Optional',
        'Additional context'
      );

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        '\n**Reason for return:**\nNot PCAFC related' +
        '\n\n**Detail:**\nAdditional context'
      );
    });

    test('Instructions are formatted properly whenever "Other" reason is selected for return', async () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      selectFromDropdown(
        'Why is this appeal being returned?',
        'Other'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Please provide the reason for return',
        'Reasoning for the return'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        '\n**Reason for return:**\nOther - Reasoning for the return'
      );
    });

    test('Instructions are formatted properly when "Other" reason is selected for return plus context', async () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      selectFromDropdown(
        'Why is this appeal being returned?',
        'Other'
      );

      expect(screen.getByText(buttonText).closest('button')).toBeDisabled();

      enterTextFieldOptions(
        'Please provide the reason for return',
        'Reasoning for the return'
      );

      expect(screen.getByText(buttonText).closest('button')).not.toBeDisabled();

      enterTextFieldOptions(
        'Provide additional context for this action Optional',
        'Additional context'
      );

      clickSubmissionButton(buttonText);

      expect(getReceivedInstructions()).toBe(
        '\n**Reason for return:**\nOther - Reasoning for the return' +
        '\n\n**Detail:**\nAdditional context'
      );
    });
  });
});
/* eslint-enable max-lines */
