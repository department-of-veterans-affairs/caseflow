/* eslint-disable max-lines */
import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import userEvent from '@testing-library/user-event';
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
  clickSubmissionButton,
  createSpyRequestPatch
} from './modalUtils';
import {
  postData,
  camoToBvaIntakeData,
  caregiverToIntakeData,
  emoToBvaIntakeData,
  rpoToBvaIntakeData,
  vhaPOToCAMOData,
  visnData
} from '../../../data/queue/taskActionModals/taskActionModalData';
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
  requestPatchSpy = createSpyRequestPatch(postData);
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('CompleteTaskModal', () => {
  describe('vha_documents_ready_for_bva_intake_review', () => {
    const taskType = 'VhaDocumentSearchTask';
    const confirmationButtonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'vha_documents_ready_for_bva_intake_for_review';
    const modalTitle = 'Ready for review';
    const modalRadioOptionVBMS = 'VBMS';
    const modalRadioOptionOther = 'Other';
    const modalOtherInstructions = 'Please indicate the source';
    const modalTextboxInstructions = 'Provide details such as file structure or file path Optional';

    test('modal title: "Ready for review"', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByText(modalTitle)).toBeTruthy();
    });

    test('modal has textbox with the instructions: "Provide details such as file structure or file path"', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByRole('textbox', { name: modalTextboxInstructions })).toBeTruthy();
    });

    test('Send button is disabled when an option has not been selected', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByRole('button', { name: confirmationButtonText })).toBeDisabled();
    });

    test('When "VBMS" is chosen from the radio options, the "Send" button is enabled', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      const radioFieldToSelect = screen.getByLabelText(modalRadioOptionVBMS);

      userEvent.click(radioFieldToSelect);

      expect(screen.getByRole('button', { name: confirmationButtonText })).toBeEnabled();
    });

    test('When "Other" is chosen from the radio options an additional text box appears', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      const radioFieldToSelect = screen.getByLabelText(modalRadioOptionOther);

      userEvent.click(radioFieldToSelect);

      expect(screen.getByRole('textbox', { name: modalOtherInstructions })).toBeTruthy();
    });

    test('When "Other" is chosen from the radio options, the button is still disabled', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      const radioFieldToSelect = screen.getByLabelText(modalRadioOptionOther);

      userEvent.click(radioFieldToSelect);

      expect(screen.getByRole('button', { name: confirmationButtonText })).toBeDisabled();
    });

    test('When something is typed into the "Other" textbox the button is enabled', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      const radioFieldToSelect = screen.getByLabelText(modalRadioOptionOther);

      userEvent.click(radioFieldToSelect);

      const otherTextbox = screen.getByRole(
        'textbox', { name: modalOtherInstructions }
      );

      userEvent.type(otherTextbox, 'Additional context');

      expect(screen.getByRole('button', { name: confirmationButtonText })).toBeEnabled();
    });

    test('When "VBMS" is chosen from the radio options, the addition text box does not appear', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      const radioFieldToSelect = screen.getByLabelText(modalRadioOptionVBMS);

      userEvent.click(radioFieldToSelect);

      expect(screen.queryByRole('textbox', { name: modalOtherInstructions })).toBeFalsy();
    });
  });

  describe('vha_return_to_board_intake', () => {
    const taskType = 'VhaDocumentSearchTask';
    const buttonText = COPY.MODAL_RETURN_BUTTON;
    const modalType = 'vha_return_to_board_intake';

    test('modal title is Return to Board Intake', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByText('Return to Board Intake')).toBeTruthy();
    });

    test('instructions textbox is present with the correct label', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByRole(
        'textbox', { name: 'Provide additional context for this action Optional' }
      )).toBeTruthy();
    });

    test('Other text area appears when other is selected in the dropdown', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      selectFromDropdown('Why is this appeal being returned?', 'Other');

      expect(screen.getByRole(
        'textbox', { name: 'Please provide the reason for return' }
      )).toBeTruthy();
    });

    test('Return button is disabled until a task is selected', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);
      expect(screen.getByRole('button', { name: buttonText })).toBeDisabled();
      // expect(screen.findByRole('button', { name: buttonText, disabled: true })).toBeTruthy();

      selectFromDropdown('Why is this appeal being returned?', 'Duplicate');

      // expect(screen.findByRole('button', { name: buttonText, disabled: false })).toBeTruthy();
      expect(screen.getByRole('button', { name: buttonText })).not.toBeDisabled();
    });

    test('if other is selected, Return button is disabled until a reason is entered', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.findByRole('button', { name: buttonText, disabled: true })).toBeTruthy();

      selectFromDropdown('Why is this appeal being returned?', 'Other');

      expect(screen.findByRole('button', { name: buttonText, disabled: true })).toBeTruthy();

      const otherTextArea = screen.getByRole(
        'textbox', { name: 'Please provide the reason for return' }
      );

      userEvent.type(otherTextArea, 'Reasoning for the return');

      expect(screen.findByRole('button', { name: buttonText, disabled: false })).toBeTruthy();
    });

    test('other instructions are formatted', async () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);
      selectFromDropdown('Why is this appeal being returned?', 'Other');
      const otherTextArea = screen.getByRole(
        'textbox', { name: 'Please provide the reason for return' }
      );

      userEvent.type(otherTextArea, 'very good reason');

      userEvent.click(await screen.findByRole('button', { name: buttonText, disabled: false }));
      expect(getReceivedInstructions()).toBe(
        '\n**Reason for return:**\nOther - very good reason'
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
      expect(screen.getByText('This appeal will be sent to VHA CAMO for review.' +
        'Please select where the documents for this appeal were returned')).toBeTruthy();
    });

    test('Submission button has correct CSS class', () => {
      renderCompleteTaskModal(modalType, vhaPOToCAMOData, taskType);

      const submissionButton = screen.getByText(buttonText).closest('button');

      expect(submissionButton).toHaveClass('usa-button');
      expect(submissionButton).not.toHaveClass('usa-button-secondary');
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
        '##### STATUS:\nDocuments for this appeal are stored in Centralized Mail Portal.' +
        '\n\n##### DETAILS:\nVHA PO -> BVA Intake\n'
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
        '##### STATUS:\nDocuments for this appeal are stored in Other Source.' +
        '\n\n##### DETAILS:\nPO -> CAMO\n'
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
      expect(screen.getByText('This appeal will be sent to VHA Program Office for review.' +
        'Please select where the documents for this appeal were returned')).toBeTruthy();
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
        '##### STATUS:\nDocuments for this appeal are stored in Centralized Mail Portal.' +
        '\n\n##### DETAILS:\nVHA PO -> BVA Intake\n'
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
        '##### STATUS:\nDocuments for this appeal are stored in Other Source.' +
        '\n\n##### DETAILS:\nPO -> CAMO\n'
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

      const submissionButton = screen.getByText(buttonText).closest('button');

      expect(submissionButton).toHaveClass('usa-button');
      expect(submissionButton).not.toHaveClass('usa-button-secondary');
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
        '##### STATUS:\nDocuments for this appeal are stored in VBMS.' +
        '\n\n##### DETAILS:\nCAREGIVER -> BVA Intake\n'
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
        '##### STATUS:\nDocuments for this appeal are stored in Other Source.' +
        '\n\n##### DETAILS:\nCAREGIVER -> BVA Intake\n'
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

      const submissionButton = screen.getByText(buttonText).closest('button');

      expect(submissionButton).toHaveClass('usa-button');
      expect(submissionButton).not.toHaveClass('usa-button-secondary');
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
        '##### STATUS:\nDocuments for this appeal are stored in Centralized Mail Portal.' +
        '\n\n##### DETAILS:\nEMO -> BVA Intake\n'
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
        '##### STATUS:\nDocuments for this appeal are stored in Other Source.' +
        '\n\n##### DETAILS:\nEMO -> BVA Intake\n'
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

      const submissionButton = screen.getByText(buttonText).closest('button');

      expect(submissionButton).toHaveClass('usa-button');
      expect(submissionButton).not.toHaveClass('usa-button-secondary');
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
        '##### STATUS:\nDocuments for this appeal are stored in Centralized Mail Portal.' +
        '\n\n##### DETAILS:\nRPO -> BVA Intake\n'
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
        '##### STATUS:\nDocuments for this appeal are stored in Other Source.' +
        '\n\n##### DETAILS:\nRPO -> BVA Intake\n'
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

      const submissionButton = screen.getByText(buttonText).closest('button');

      expect(submissionButton).toHaveClass('usa-button');
      expect(submissionButton).not.toHaveClass('usa-button-secondary');
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
        '\n##### REASON FOR RETURN:\n' +
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

      const submissionButton = screen.getByText(buttonText).closest('button');

      expect(submissionButton).toHaveClass('usa-button');
      expect(submissionButton).not.toHaveClass('usa-button-secondary');
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
        '\n##### REASON FOR RETURN:\nNot PCAFC related'
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
        '\n##### REASON FOR RETURN:\nNot PCAFC related' +
        '\n\n##### DETAILS:\nAdditional context'
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
        '\n##### REASON FOR RETURN:\nOther - Reasoning for the return'
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
        '\n##### REASON FOR RETURN:\nOther - Reasoning for the return' +
        '\n\n##### DETAILS:\nAdditional context'
      );
    });
  });
});
/* eslint-enable max-lines */
