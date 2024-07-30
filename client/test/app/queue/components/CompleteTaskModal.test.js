import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import COPY from '../../../../COPY';

import {
  postData,
  camoToBvaIntakeData,
  caregiverToIntakeData,
  emoToBvaIntakeData,
  rpoToBvaIntakeData
} from '../../../data/queue/taskActionModals/completeTaskActionModalData';
import * as uiActions from 'app/queue/uiReducer/uiActions';
import CompleteTaskModal from 'app/queue/components/CompleteTaskModal';

let requestPatchSpy;

const createQueueReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
};

const getAppealId = (storeValues) => {
  return Object.keys(storeValues.queue.appeals)[0];
};

const getTaskId = (storeValues, taskType) => {
  const tasks = storeValues.queue.amaTasks;

  return Object.keys(tasks).find((key) => (
    tasks[key].type === taskType
  ));
};

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
          return <CompleteTaskModal {...props} modalType={modalType} appealId={appealId} taskId={taskId} />;
        }} path={path} />
      </MemoryRouter>
    </Provider>
  );
};

const enterModalRadioOptions = (radioSelection, instructionsFieldName, instructions, buttonText, otherSource) => {
  const radioFieldToSelect = screen.getByLabelText(radioSelection);
  const instructionsField = screen.getByRole('textbox', { name: instructionsFieldName });

  userEvent.click(radioFieldToSelect);
  userEvent.type(instructionsField, instructions);
  if (otherSource) {
    const otherSourceField = screen.getByRole('textbox', { name: 'Please indicate the source' });

    userEvent.type(otherSourceField, otherSource);
  }

  userEvent.click(screen.getByRole('button', { name: buttonText }));
};

const selectFromDropdown = async (
  dropdownName, dropdownSelection
) => {
  const dropdown = screen.getByRole('combobox', { name: dropdownName });

  userEvent.click(dropdown);

  userEvent.click(screen.getByRole('option', { name: dropdownSelection }));
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
  describe('vha_documents_ready_for_bva_intake_review', () => {
    const taskType = 'VhaDocumentSearchTask';
    const confirmationButtonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'vha_documents_ready_for_bva_intake_for_review';
    const modalTitle = 'Ready for review';
    const modalRadioOptionVBMS = 'VBMS';
    const modalRadioOptionOther = 'Other';
    const modalOtherInstructions = 'Please indicate the source';
    const modalTextboxInstructions = 'Provide details such as file structure or file path';

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

      expect(screen.findByRole('button', { name: buttonText, disabled: true })).toBeTruthy();

      selectFromDropdown('Why is this appeal being returned?', 'Duplicate');

      expect(screen.findByRole('button', { name: buttonText, disabled: false })).toBeTruthy();
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

  describe('vha_caregiver_support_send_to_board_intake_for_review', () => {
    const taskType = 'VhaDocumentSearchTask';
    const buttonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'vha_caregiver_support_send_to_board_intake_for_review';

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('When VBMS is chosen in Modal', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      enterModalRadioOptions(
        'VBMS',
        'Provide details such as file structure or file path Optional',
        'CAREGIVER -> BVA Intake',
        buttonText
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in VBMS.' +
        '\n\n**Detail:**\n\nCAREGIVER -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      enterModalRadioOptions(
        'Other',
        'Provide details such as file structure or file path Optional',
        'CAREGIVER -> BVA Intake',
        buttonText,
        'Other Source'
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Other Source.' +
        '\n\n**Detail:**\n\nCAREGIVER -> BVA Intake\n'
      );
    });
  });

  describe('emo_send_to_board_intake_for_review', () => {
    const taskType = 'EducationDocumentSearchTask';
    const buttonText = COPY.MODAL_SUBMIT_BUTTON;
    const modalType = 'emo_send_to_board_intake_for_review';

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('When Centralized Mail Portal is chosen in Modal', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Centralized Mail Portal',
        'Provide details such as file structure or file path Optional',
        'EMO -> BVA Intake',
        buttonText
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Centralized Mail Portal.' +
        '\n\n**Detail:**\n\nEMO -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal(modalType, emoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Other',
        'Provide details such as file structure or file path Optional',
        'EMO -> BVA Intake',
        buttonText,
        'Other Source'
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Other Source.' +
        '\n\n**Detail:**\n\nEMO -> BVA Intake\n'
      );
    });
  });

  describe('rpo_send_to_board_intake_for_review', () => {
    const taskType = 'EducationAssessDocumentationTask';
    const buttonText = COPY.MODAL_SUBMIT_BUTTON;
    const modalType = 'rpo_send_to_board_intake_for_review';

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal(modalType, rpoToBvaIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('When Centralized Mail Portal is chosen in Modal', () => {
      renderCompleteTaskModal(modalType, rpoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Centralized Mail Portal',
        'Provide details such as file structure or file path Optional',
        'RPO -> BVA Intake',
        buttonText
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Centralized Mail Portal.' +
        '\n\n**Detail:**\n\nRPO -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal(modalType, rpoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Other',
        'Provide details such as file structure or file path Optional',
        'RPO -> BVA Intake',
        buttonText,
        'Other Source'
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Other Source.' +
        '\n\n**Detail:**\n\nRPO -> BVA Intake\n'
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

    test('Instructions are formatted properly whenever a non-other reason is selected for return', async () => {
      renderCompleteTaskModal(modalType, caregiverToIntakeData, taskType);

      selectFromDropdown(
        'Why is this appeal being returned?',
        'Not PCAFC related'
      );

      userEvent.click(await screen.findByRole('button', { name: buttonText, disabled: false }));

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

      const optionalTextArea = screen.getByRole(
        'textbox', { name: 'Provide additional context for this action Optional' }
      );

      userEvent.type(optionalTextArea, 'Additional context');

      userEvent.click(await screen.findByRole('button', { name: buttonText, disabled: false }));

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

      const otherTextArea = screen.getByRole(
        'textbox', { name: 'Please provide the reason for return' }
      );

      userEvent.type(otherTextArea, 'Reasoning for the return');

      userEvent.click(await screen.findByRole('button', { name: buttonText, disabled: false }));

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

      const otherTextArea = screen.getByRole(
        'textbox', { name: 'Please provide the reason for return' }
      );

      userEvent.type(otherTextArea, 'Reasoning for the return');

      const optionalTextArea = screen.getByRole(
        'textbox', { name: 'Provide additional context for this action Optional' }
      );

      userEvent.type(optionalTextArea, 'Additional context');

      userEvent.click(await screen.findByRole('button', { name: buttonText, disabled: false }));

      expect(getReceivedInstructions()).toBe(
        '\n**Reason for return:**\nOther - Reasoning for the return' +
        '\n\n**Detail:**\nAdditional context'
      );
    });
  });
});
