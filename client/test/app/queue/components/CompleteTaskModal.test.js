import React from 'react';
import { MemoryRouter } from 'react-router';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

import {
  postData,
  camoToBvaIntakeData,
  camoToProgramOfficeToCamoData
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

    test('modal title is Send to Board Intake', () => {
      renderCompleteTaskModal('vha_send_to_board_intake', camoToBvaIntakeData, taskType);

      expect(screen.getByText('Send to Board Intake')).toBeTruthy();
    });

    test('CAMO Notes section only appears once whenever CAMO sends appeal back to BVA Intake', () => {
      renderCompleteTaskModal('vha_send_to_board_intake', camoToBvaIntakeData, taskType);

      const radioFieldToSelect = screen.getByLabelText('Correct documents have been successfully added');
      const instructionsField = screen.getByRole('textbox', { name: 'Provide additional context and/or documents:' });

      userEvent.click(radioFieldToSelect);
      userEvent.type(instructionsField, 'CAMO -> BVA Intake');

      userEvent.click(screen.getByRole('button', { name: 'Submit' }));

      let dataParam = requestPatchSpy.mock.calls[0][1];
      let taskInstructions = dataParam.data.task.instructions;

      expect(taskInstructions).toBe('\n**CAMO Notes:** CAMO -> BVA Intake');
    });

    test('PO Details appear next to Program Office Notes section', () => {
      renderCompleteTaskModal('vha_send_to_board_intake', camoToProgramOfficeToCamoData, taskType);

      const radioFieldToSelect = screen.getByLabelText('Correct documents have been successfully added');
      const instructionsField = screen.getByRole('textbox', { name: 'Provide additional context and/or documents:' });

      userEvent.click(radioFieldToSelect);
      userEvent.type(instructionsField, 'CAMO -> BVA Intake');

      userEvent.click(screen.getByRole('button', { name: 'Submit' }));

      let dataParam = requestPatchSpy.mock.calls[0][1];
      let taskInstructions = dataParam.data.task.instructions;

      /* eslint-disable-next-line max-len */
      expect(taskInstructions).toBe('\n**Status:** Correct documents have been successfully added\n\n**CAMO Notes:** CAMO -> BVA Intake\n\n**Program Office Notes:** Documents for this appeal are stored in VBMS.\n\n**Detail:**\n\n PO back to CAMO!\n\n');
    });
  });
});
