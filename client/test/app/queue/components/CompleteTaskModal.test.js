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
  camoToProgramOfficeToCamoData,
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
  describe('vha_send_to_board_intake', () => {
    const taskType = 'VhaDocumentSearchTask';
    const buttonText = COPY.MODAL_SUBMIT_BUTTON;
    const modalType = 'vha_send_to_board_intake';

    test('modal title is Send to Board Intake', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByText('Send to Board Intake')).toBeTruthy();
    });

    test('CAMO Notes section only appears once whenever CAMO sends appeal back to BVA Intake', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      enterModalRadioOptions(
        'Correct documents have been successfully added',
        'Provide additional context and/or documents:',
        'CAMO -> BVA Intake',
        buttonText
      );

      expect(getReceivedInstructions()).toBe(
        '\n**Status:** Correct documents have been successfully added\n\n' +
        '**CAMO Notes:** CAMO -> BVA Intake'
      );
    });

    test('PO Details appear next to Program Office Notes section', () => {
      renderCompleteTaskModal(modalType, camoToProgramOfficeToCamoData, taskType);

      enterModalRadioOptions(
        'Correct documents have been successfully added',
        'Provide additional context and/or documents:',
        'CAMO -> BVA Intake',
        buttonText
      );

      expect(getReceivedInstructions()).toBe(
        '\n**Status:** Correct documents have been successfully added\n\n' +
        '**CAMO Notes:** CAMO -> BVA Intake\n\n' +
        '**Program Office Notes:** Documents for this appeal are stored in VBMS.\n\n' +
        '**Detail:**\n\n PO back to CAMO!\n\n'
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

      enterModalRadioOptions(
        'Correct documents have been successfully added',
        'Provide additional context and/or documents:',
        'Null test',
        buttonText
      );

      expect(getReceivedInstructions()).toBe(
        '\n**Status:** Correct documents have been successfully added' +
        '\n\n**CAMO Notes:** Null test\n' +
        '\n**Program Office Notes:** Documents for this appeal are stored in VBMS.' +
        '\n\n**Detail:**' +
        '\n\n PO back to CAMO!\n\n'
      );
    });
  });

  describe('vha_documents_ready_for_ready_for_bva_intake_review', () => {
    const taskType = 'VhaDocumentSearchTask';
    const confirmationButtonText = COPY.MODAL_SEND_BUTTON;
    const modalType = 'vha_documents_ready_for_bva_intake_review';
    const modalTitle = 'Ready for Review';
    const modalDropdownName = 'Please select where the documents for this appeal are stored.';
    const modalDropdownOptionVBMS = 'VBMS';
    const modalDropdownOptionOther = 'Other';
    const modalOtherInstructions = 'This appeal will be sent to Board intake for reveiw.\n\nPlease provide the source for the documents';
    const modalTextboxInstructions = 'Provide additional context and/or documents:';

    test('modal title: "Ready for Review"', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByText(modalTitle)).toBeTruthy();
    });

    test('modal has textbox with the instructions: "Provide additional context and/or documents:"', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByRole('textbox', { name: modalTextboxInstructions })).toBeTruthy();
    });

    test('Submit button is disabled when a option from the drop down has not been selected', () => {
      renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

      expect(screen.getByRole('button', { name: confirmationButtonText })).toBeDisabled();
    });

    test(
      'When "Other" is chosen from the dropdown options an additional text box appears and the button is still disabled'
      , () => {
        renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

        selectFromDropdown(modalDropdownName, modalDropdownOptionOther);

        expect(screen.getByRole('textbox', { name: modalOtherInstructions })).toBeTruthy();

        expect(screen.getByRole('button', { name: confirmationButtonText })).toBeDisabled();
      });

    // test('When "VBMS" is chosen from the dropdown options the addition text box does not appear', () => {
    //   renderCompleteTaskModal(modalType, camoToBvaIntakeData, taskType);

    //   selectFromDropdown(modalDropdownName, modalDropdownOptionVBMS);

    //   expect(screen.getByRole('button', { name: confirmationButtonText })).toBeEnabled();
    // });
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
