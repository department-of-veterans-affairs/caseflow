import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, compose, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import { BrowserRouter as Router } from 'react-router-dom';
import COPY from '../../../../../COPY';
import TASK_ACTIONS from '../../../../../constants/TASK_ACTIONS';
import CORRESPONDENCE_RETURN_TO_INBOUND_OPS_REASONS
  from '../../../../../constants/CORRESPONDENCE_RETURN_TO_INBOUND_OPS_REASONS';
import CorrespondenceReturnToInboundOpsModal
  from '../../../../../app/queue/components/CorrespondenceReturnToInboundOpsModal';
import thunk from 'redux-thunk';

const mockProps = {
  0: 'modal/return_to_inbound_ops',
  correspondence_uuid: '123abc',
  task_id: '32062',
  correspondenceInfo: {
    tasksUnrelatedToAppeal: [
      {
        label: 'Other motion',
        assignedOn: '11/27/2024',
        assignedTo: 'Litigation Support',
        type: 'Organization',
        instructions: [
          'Interest noted in telephone call of mm/dd/yy\n'
        ],
        availableActions: [
          {
            label: 'Assign to team',
            func: 'assign_corr_task_to_team',
            value: 'assign_to_team',
            data: {
              modal_title: 'Assign task',
              modal_body: 'Select a user',
              message_title: 'Provide context and instructions for this action',
              redirect_after: '/queue/correspondence/:correspondence_uuid/'
            }
          },
          {
            label: 'Assign to person',
            func: 'assign_corr_task_to_person',
            value: 'assign_to_person',
            data: {
              modal_title: 'Assign task',
              modal_body: 'Select a user',
              message_title: 'Provide context and instructions for this action',
              redirect_after: '/queue/correspondence/:correspondence_uuid/'
            }
          },
          {
            label: 'Cancel task',
            func: 'cancel_correspondence_task_data',
            value: 'modal/cancel_correspondence_task',
            data: {
              modal_title: 'Cancel task',
              modal_body: 'Cancelling this task will return it to Jasper Bloom',
              message_title: "Task for Bob Smithdooley's case has been cancelled",
              message_detail: 'If you have made a mistake, please email Jasper Bloom to manage any changes.',
              redirect_after: '/queue/correspondence/:correspondence_uuid/'
            }
          },
          {
            label: 'Mark task complete',
            func: 'complete_correspondence_task_data',
            value: 'modal/complete_correspondence_task',
            data: {
              modal_title: 'Mark as complete',
              modal_body: 'Provide context and instructions for the action',
              message_title: "Task for Bob Smithdooley's case has been completed",
              message_detail: "Task for Jasper Bloom's case has been completed",
              redirect_after: '/queue/correspondence/:correspondence_uuid/'
            }
          },
          {
            label: 'Return to Inbound Ops',
            value: 'modal/return_to_inbound_ops'
          }
        ],
        uniqueId: 32062,
        reassignUsers: [
          'LIT_SUPPORT_USER',
        ],
        assignedToOrg: true,
        assignedBy: null,
        status: 'assigned'
      }
    ]
  },
  returnTaskToInboundOps: jest.fn()
};

const initialState = {
  correspondenceDetails: {
    correspondenceInfo: {
      tasksUnrelatedToAppeal: mockProps.correspondenceInfo.tasksUnrelatedToAppeal,
    },
    bannerAlert: null
  }
};

const store = createStore(rootReducer, initialState, compose(applyMiddleware(thunk)));

const renderComponent = (props = mockProps) => {
  return render(
    <Provider store={store}>
      <Router>
        <CorrespondenceReturnToInboundOpsModal {...props} />
      </Router>
    </Provider>
  );
};

describe('CorrespondenceReturnToInboundOpsModal', () => {
  beforeEach(() => {
    renderComponent();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders the modal with the correct title', () => {
    const titleElement = screen.getByRole('heading', { level: 1 });

    expect(titleElement).toHaveTextContent(TASK_ACTIONS.COR_RETURN_TO_INBOUND_OPS.label);
  });

  it('renders the RadioField components', () => {
    expect(screen.getByText(COPY.CORRESPONDENCE_RETURN_TO_INBOUND_OPS_MODAL_SUBTITLE)).toBeInTheDocument();
    expect(screen.getByText(CORRESPONDENCE_RETURN_TO_INBOUND_OPS_REASONS.not_appropriate)).toBeInTheDocument();
    expect(screen.getByText(CORRESPONDENCE_RETURN_TO_INBOUND_OPS_REASONS.clarification_needed)).toBeInTheDocument();
    expect(screen.getByText(CORRESPONDENCE_RETURN_TO_INBOUND_OPS_REASONS.other)).toBeInTheDocument();
  });

  it('disables the submit button if the form is not valid', () => {
    const radioInputOtherReason = screen.getByDisplayValue('Other');
    const submitButton = screen.getByText('Return');

    fireEvent.click(radioInputOtherReason);

    expect(submitButton).toBeInTheDocument();
    expect(submitButton).toBeDisabled();
  });

  it('enables the submit button when other reason is selected and instructions are filled', async () => {
    const radioInputOtherReason = screen.getByDisplayValue('Other');
    const submitButton = screen.getByText('Return');

    fireEvent.click(radioInputOtherReason);
    const textField = await screen.getByRole('textbox', { name: COPY.CORRESPONDENCE_RETURN_TO_INBOUND_OPS_MODAL_OTHER_REASON_TITLE });

    fireEvent.change(textField, { target: { value: 'anything' } });

    expect(submitButton).toBeInTheDocument();
    expect(submitButton).toBeEnabled();
  });
});
