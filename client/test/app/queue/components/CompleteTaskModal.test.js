import React from 'react';
import { MemoryRouter } from 'react-router';
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

  return render(
    <Provider store={store}>
      <MemoryRouter>
        <CompleteTaskModal
          modalType={modalType}
          appealId={appealId}
          taskId={taskId}
        />
      </MemoryRouter>
    </Provider>
  );
};

const enterModalOptions = (radioSelection, instructionsFieldName, instructions, buttonText, otherSource) => {
  const radioFieldToSelect = screen.getByLabelText(radioSelection);
  const instructionsField = screen.getByRole('textbox', { name: instructionsFieldName });

  userEvent.click(radioFieldToSelect);
  userEvent.type(instructionsField, instructions);
  if (otherSource) {
    const otherSourceField = screen.getByRole('textbox', { name: 'Please indicate the source' });

    userEvent.type(otherSourceField, otherSource)
  }

  userEvent.click(screen.getByRole('button', { name: buttonText  }));
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

    test('modal title is Send to Board Intake', () => {
      renderCompleteTaskModal('vha_send_to_board_intake', camoToBvaIntakeData, taskType);

      expect(screen.getByText('Send to Board Intake')).toBeTruthy();
    });

    test('CAMO Notes section only appears once whenever CAMO sends appeal back to BVA Intake', () => {
      renderCompleteTaskModal('vha_send_to_board_intake', camoToBvaIntakeData, taskType);

      enterModalOptions(
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
      renderCompleteTaskModal('vha_send_to_board_intake', camoToProgramOfficeToCamoData, taskType);

      enterModalOptions(
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
  });

  describe('vha_caregiver_support_send_to_board_intake_for_review', () => {
    const taskType = 'VhaDocumentSearchTask';
    const buttonText = COPY.MODAL_SEND_BUTTON

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal('vha_caregiver_support_send_to_board_intake_for_review', caregiverToIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('When VBMS is chosen in Modal', () => {
      renderCompleteTaskModal('vha_caregiver_support_send_to_board_intake_for_review', caregiverToIntakeData, taskType);

      enterModalOptions(
        'VBMS',
        'Provide details such as file structure or file path',
        'CAREGIVER -> BVA Intake',
        buttonText
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in VBMS.' +
        '\n\n**Detail:**\n\nCAREGIVER -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal('vha_caregiver_support_send_to_board_intake_for_review', caregiverToIntakeData, taskType);

      enterModalOptions(
        'Other',
        'Provide details such as file structure or file path',
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

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal('emo_send_to_board_intake_for_review', emoToBvaIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('When Centralized Mail Portal is chosen in Modal', () => {
      renderCompleteTaskModal('emo_send_to_board_intake_for_review', emoToBvaIntakeData, taskType);

      enterModalOptions(
        'Centralized Mail Portal',
        'Provide details such as file structure or file path',
        'EMO -> BVA Intake',
        buttonText
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Centralized Mail Portal.' +
        '\n\n**Detail:**\n\nEMO -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal('emo_send_to_board_intake_for_review', emoToBvaIntakeData, taskType);

      enterModalOptions(
        'Other',
        'Provide details such as file structure or file path',
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

    test('modal title is Ready for Review', () => {
      renderCompleteTaskModal('emo_send_to_board_intake_for_review', rpoToBvaIntakeData, taskType);
      expect(screen.getByText('Ready for review')).toBeTruthy();
    });

    test('When Centralized Mail Portal is chosen in Modal', () => {
      renderCompleteTaskModal('rpo_send_to_board_intake_for_review', rpoToBvaIntakeData, taskType);

      enterModalOptions(
        'Centralized Mail Portal',
        'Provide details such as file structure or file path',
        'RPO -> BVA Intake',
        buttonText
      );
      expect(getReceivedInstructions()).toBe(
        'Documents for this appeal are stored in Centralized Mail Portal.' +
        '\n\n**Detail:**\n\nRPO -> BVA Intake\n'
      );
    });

    test('When Other is Chosen in Modal', () => {
      renderCompleteTaskModal('rpo_send_to_board_intake_for_review', rpoToBvaIntakeData, taskType);

      enterModalOptions(
        'Other',
        'Provide details such as file structure or file path',
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
});
