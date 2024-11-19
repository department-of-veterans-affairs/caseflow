import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen, act } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import UploadTranscriptionVBMSNoErrorModal from '../../../../app/queue/UploadTranscriptionVBMSNoErrorModal';
import {
  createQueueReducer,
  getAppealId,
  getTaskId
} from './modalUtils';
import { UploadTranscriptionVBMSNoErrorData } from '../../../data/queue/taskActionModals/taskActionModalData';
import userEvent from '@testing-library/user-event';
import ApiUtil from '../../../../app/util/ApiUtil';
jest.mock('../../../../app/util/ApiUtil');

const renderUploadTranscriptionVBMSNoErrorModal = (storeValues, taskType) => {
  const appealId = getAppealId(storeValues);
  const taskId = getTaskId(storeValues, taskType);

  const queueReducer = createQueueReducer(storeValues);
  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  const path = `/queue/appeals/${appealId}/tasks/${taskId}/modal/upload_transcription_vbms`;

  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Route component={(props) => {
          return <UploadTranscriptionVBMSNoErrorModal {...props.match.params} />;
        }} path="/queue/appeals/:appealId/tasks/:taskId/modal/upload_transcription_vbms" />
      </MemoryRouter>
    </Provider>
  );
};

describe('UploadTranscriptionVBMSNoErrorModal', () => {
  const setUpModal = () => renderUploadTranscriptionVBMSNoErrorModal(UploadTranscriptionVBMSNoErrorData, 'RootTask');

  describe('on modal open', () => {
    test('modal title: "Upload transcript to VBMS"', () => {
      setUpModal();

      expect(screen.getByRole('heading', { level: 1 })).toBeTruthy();
    });

    test('submit button is initially disabled', () => {
      setUpModal();

      expect(screen.getByText('Upload to VBMS', { selector: 'button' })).toBeDisabled();
    });
  });

  describe('Button Disabled until text field is populated', () => {
    const instructionsLabel = 'Please provide context and instructions for this action';

    test('instructions field is present', async () => {
      jest.useFakeTimers('modern');
      setUpModal();

      const response = { status: 200, body: { document_presence: true } };

      ApiUtil.get.mockResolvedValue(response);
      await act(async() => jest.runAllTimers());
      userEvent.type(screen.getByLabelText(instructionsLabel), 'This is a test.');
      jest.runAllTimers();
      expect(screen.getByText('Upload to VBMS', { selector: 'button' })).toBeEnabled();
    });
  });
});
