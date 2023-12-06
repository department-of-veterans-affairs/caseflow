import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk'
import CompleteHearingPostponementRequestModal
  from 'app/queue/components/hearingMailRequestModals/CompleteHearingPostponementRequestModal';
import { completeHearingPostponementRequestData }
  from '../../../../data/queue/taskActionModals/taskActionModalData';
import {
  createQueueReducer,
  getAppealId,
  getTaskId,
  enterModalRadioOptions,
  enterInputValue,
  enterTextFieldOptions
} from '../modalUtils';
import COPY from '../../../../../COPY';
import { add, format } from 'date-fns';

const renderCompleteHprModal = (storeValues) => {
  const appealId = getAppealId(storeValues);
  const taskId = getTaskId(storeValues, 'HearingPostponementRequestMailTask');
  const queueReducer = createQueueReducer(storeValues);
  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  const path = `/queue/appeals/${appealId}/tasks/${taskId}/modal/complete_and_postpone`;

  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Route component={(props) => {
          return <CompleteHearingPostponementRequestModal {...props.match.params} />;
        }} path="/queue/appeals/:appealId/tasks/:taskId/modal/complete_and_postpone" />
      </MemoryRouter>
    </Provider>
  );
};

describe('CompleteHearingPostponementRequestModal', () => {
  const modalAction = 'Mark as complete';
  const [granted, denied] = ['Granted', 'Denied'];
  const datePrompt = 'Date of ruling:';
  const [reschedule, scheduleLater] = ['Reschedule immediately', 'Send to Schedule Veteran list'];
  const instructions = `${COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}:`;

  const fields = {
    granted: () => screen.getByRole('radio', { name: granted }),
    denied: () => screen.getByRole('radio', { name: denied }),
    reschedule: () => screen.queryByRole('radio', { name: reschedule }),
    scheduleLater: () => screen.queryByRole('radio', { name: scheduleLater }),
    date: () => screen.getByLabelText(datePrompt),
    instructions: () => screen.getByRole('textbox', { name: instructions }),
    submit: () => screen.getByRole('button', { name: modalAction })
  };

  const formatDate = (date) => format(date, 'yyyy-MM-dd').toString();
  const today = formatDate(new Date());
  const futureDate = formatDate(add(new Date(), { days: 2 }));

  describe('on modal open', () => {
    test('modal title: "Mark as complete"', () => {
      renderCompleteHprModal(completeHearingPostponementRequestData);

      expect(screen.getByRole('heading', { name: modalAction })).toBeInTheDocument();
    });

    describe('judge ruling radio fields', () => {
      const radioPrompt = 'What is the Judge’s ruling on the motion to postpone?';

      test('have text prompt "What is the Judge’s ruling on the motion to postpone?"', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        expect(screen.getByText(radioPrompt)).toBeInTheDocument();
      });

      test('have two options: "Granted" and "Denied"', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        expect(screen.getAllByRole('radio')).toHaveLength(2);
        expect(fields.granted()).toBeInTheDocument();
        expect(fields.denied()).toBeInTheDocument();
      });
    });

    describe('date selector', () => {
      test('has date input with text prompt "Date of ruling:"', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        expect(fields.date()).toBeInTheDocument();
      });
    });

    describe('text area field', () => {
      test('has text prompt "Provide instructions and context for this action:"', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        expect(fields.instructions()).toBeInTheDocument();
      });
    });

    describe('schedule options radio fields', () => {
      test('are not present', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        expect(screen.queryByRole('radio', { name: reschedule })).not.toBeInTheDocument();
        expect(screen.queryByRole('radio', { name: scheduleLater })).not.toBeInTheDocument();
      });
    });

    describe('submit button', () => {
      test('submit button is initially disabled', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        expect(fields.submit()).toBeDisabled();
      });
    });
  });

  describe('on determine judge ruling', () => {
    describe('radio option "Granted" is selected', () => {
      test('radio fields with scheduling options are made visible', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        enterModalRadioOptions(granted);
        expect(fields.reschedule()).toBeInTheDocument();
        expect(fields.scheduleLater()).toBeInTheDocument();
      });
    });

    describe('radio option "Denied" is selected', () => {
      test('radio fields with scheduling options are not visible', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        enterModalRadioOptions(denied);
        expect(screen.queryByRole('radio', { name: reschedule })).not.toBeInTheDocument();
        expect(screen.queryByRole('radio', { name: scheduleLater })).not.toBeInTheDocument();
      });
    });
  });

  describe('on entering a decision date into date selector', () => {
    const dateErrorMessage = 'Dates cannot be in the future';

    describe('date is in the future', () => {
      test('date error message appears', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        enterInputValue(datePrompt, futureDate);
        expect(screen.getByText(dateErrorMessage)).toBeInTheDocument();
      });
    });

    describe('date is not in the future', () => {
      test('date error message is not present', () => {
        renderCompleteHprModal(completeHearingPostponementRequestData);

        enterInputValue(datePrompt, today);
        expect(screen.queryByText(dateErrorMessage)).not.toBeInTheDocument();
      });
    });
  });

  describe('on validate form', () => {
    const modalEvents = {
      granted: () => enterModalRadioOptions(granted),
      denied: () => enterModalRadioOptions(denied),
      date: () => enterInputValue(datePrompt, today),
      reschedule: () => enterModalRadioOptions(reschedule),
      instructions: () => enterTextFieldOptions(instructions, 'test')
    };

    const completeForm = (eventSequence) => {
      eventSequence.forEach((event) => modalEvents[event].call());
    };

    const testValidForm = (eventSequence) => {
      describe('all requried fields are valid', () => {
        test('submit button is enabled', () => {
          renderCompleteHprModal(completeHearingPostponementRequestData);

          completeForm(eventSequence);
          expect(fields.submit()).not.toBeDisabled();
        });
      });
    };

    const runInvalidationTestOnEachField = (eventSequences) => {
      describe('any field is invalid', () => {
        describe.each(eventSequences)('%s field is invalid', (invalidField, eventSequence) => {
          test('submit button is disabled', () => {
            renderCompleteHprModal(completeHearingPostponementRequestData);

            completeForm(eventSequence);
            expect(fields[invalidField].call()).toBeInTheDocument();
            expect(fields.submit()).toBeDisabled();
          });
        });
      });
    };

    describe('judge ruling is "Granted"', () => {
      const eventSequences = [
        ['granted', ['date', 'instructions']],
        ['date', ['granted', 'reschedule', 'instructions']],
        ['reschedule', ['granted', 'date', 'instructions']],
        ['instructions', ['granted', 'date', 'reschedule']]
      ];

      testValidForm(['granted', 'date', 'reschedule', 'instructions']);
      runInvalidationTestOnEachField(eventSequences);
    });

    describe('judge ruling is "Denied"', () => {
      const eventSequences = [
        ['denied', ['date', 'instructions']],
        ['date', ['denied', 'instructions']],
        ['instructions', ['denied', 'date']]
      ];

      testValidForm(['denied', 'date', 'instructions']);
      runInvalidationTestOnEachField(eventSequences);
    });
  });
});
