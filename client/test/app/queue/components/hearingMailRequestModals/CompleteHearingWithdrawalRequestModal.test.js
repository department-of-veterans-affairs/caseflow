import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk'
import CompleteHearingWithdrawalRequestModal
  from 'app/queue/components/hearingMailRequestModals/CompleteHearingWithdrawalRequestModal';
import { completeHearingWithdrawalRequestData }
  from '../../../../data/queue/taskActionModals/taskActionModalData';
import {
  createQueueReducer,
  getAppealId,
  getTaskId,
  enterTextFieldOptions
} from '../modalUtils';
import COPY from '../../../../../COPY';

const renderCompleteWprModal = (storeValues) => {
  const appealId = getAppealId(storeValues);
  const taskId = getTaskId(storeValues, 'HearingWithdrawalRequestMailTask');
  const queueReducer = createQueueReducer(storeValues);
  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  const path = `/queue/appeals/${appealId}/tasks/${taskId}/modal/complete_and_withdraw`;

  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Route component={(props) => {
          return <CompleteHearingWithdrawalRequestModal {...props.match.params} />;
        }} path="/queue/appeals/:appealId/tasks/:taskId/modal/complete_and_withdraw" />
      </MemoryRouter>
    </Provider>
  );
};

describe('CompleteHearingWithdrawalRequestModal', () => {
  const instructions = `${COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}:`;
  const buttonText = 'Mark as complete & withdraw hearing';
  const button = () => screen.getByRole('button', { name: buttonText });

  describe('on modal open', () => {
    test('modal has title "Mark as complete and withdraw hearing"', () => {
      renderCompleteWprModal(completeHearingWithdrawalRequestData);

      expect(screen.getByRole('heading', {
        name: 'Mark as complete and withdraw hearing'
      })).toBeInTheDocument();
    });

    test('modal body has appropiate text', () => {
      renderCompleteWprModal(completeHearingWithdrawalRequestData);

      expect(screen.getByText('By marking this task as complete, you will withdraw the hearing.')).toBeInTheDocument();
      expect(screen.getByText(COPY.WITHDRAW_HEARING.AMA.MODAL_BODY)).toBeInTheDocument();
    });

    test('textarea field has text prompt "Provide instructions and context for this action:"', () => {
      renderCompleteWprModal(completeHearingWithdrawalRequestData);

      expect(screen.getByRole('textbox', { name: instructions })).toBeInTheDocument();
    });

    test('submit button is initially disabled', () => {
      renderCompleteWprModal(completeHearingWithdrawalRequestData);

      expect(button()).toBeDisabled();
    });
  });

  describe('on validate form', () => {
    test('submit button is enabled when valid instructions entered', () => {
      renderCompleteWprModal(completeHearingWithdrawalRequestData);

      expect(button()).toBeDisabled();

      enterTextFieldOptions(instructions, 'test');
      expect(button()).not.toBeDisabled();
    });
  });
});
