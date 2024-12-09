import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, compose, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import { BrowserRouter as Router } from 'react-router-dom';
import COPY from '../../../../COPY';
import CorrespondenceChangeTaskTypeModal from 'app/queue/components/CorrespondenceChangeTaskTypeModal';
import userEvent from '@testing-library/user-event';
import thunk from 'redux-thunk';
import { INTAKE_FORM_TASK_TYPES } from 'app/queue/constants';

describe('CorrespondenceChangeTaskTypeModal', () => {
  const mockProps = {
    task_id: '123',
    correspondence_uuid: '456',
    task: {
      label: 'Original Task Label',
      uniqueId: 123,
      instructions: []
    },
    correspondenceInfo: {
      tasksUnrelatedToAppeal: [
        { uniqueId: 123, label: 'Original Task Label', instructions: [] },
        { uniqueId: 124, label: 'Other Task Label', instructions: [] }
      ]
    },
    changeTaskTypeNotRelatedToAppeal: jest.fn(),
    error: null
  };

  const renderComponent = (props = mockProps) => {
    const initialState = {
      correspondenceDetails: {
        correspondenceInfo: {
          tasksUnrelatedToAppeal: props.correspondenceInfo.tasksUnrelatedToAppeal,
        },
        bannerAlert: null
      },
      ui: {
        messages: {
          error: props.error
        },
        saveState: {
          saveSuccessful: {}
        }
      }
    };
    const store = createStore(rootReducer, initialState, compose(applyMiddleware(thunk)));

    return render(
      <Provider store={store}>
        <Router>
          <CorrespondenceChangeTaskTypeModal {...props} />
        </Router>
      </Provider>
    );
  };

  it('renders the modal with the correct title', () => {
    renderComponent();

    const titleElement = screen.getByRole('heading', { level: 1 });

    expect(titleElement).toHaveTextContent(COPY.CHANGE_TASK_TYPE_SUBHEAD);
  });

  it('renders the SearchableDropdown and TextareaField components', () => {
    renderComponent();

    expect(screen.getByText('Select an action type...')).toBeInTheDocument();
    expect(screen.getByLabelText(COPY.PLEASE_PROVIDE_CONTEXT_AND_INSTRUCTIONS_LABEL)).toBeInTheDocument();
  });

  it('disables the submit button if the form is not valid', () => {
    renderComponent();

    const submitButton = screen.getByRole('button', { name: COPY.CHANGE_TASK_TYPE_SUBHEAD });

    expect(submitButton).toBeInTheDocument();
    expect(submitButton).toBeDisabled();
  });

  it('enables the submit button when both the dropdown and instructions are filled', () => {
    renderComponent();

    userEvent.type(screen.getByRole('combobox'), 'CAVC{enter}');
    userEvent.type(screen.getByLabelText(COPY.PLEASE_PROVIDE_CONTEXT_AND_INSTRUCTIONS_LABEL), 'test instructions');

    const submitButton = screen.getByRole('button', { name: COPY.CHANGE_TASK_TYPE_SUBHEAD });

    expect(submitButton).not.toBeDisabled();
  });

  it('renders dropdown with correct options', () => {
    renderComponent();

    const dropdown = screen.getByRole('combobox',
      { name: 'Select another task type from the list of available options:' });

    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

    // Ensure each option is rendered
    INTAKE_FORM_TASK_TYPES.unrelatedToAppeal.forEach((option) => {
      expect(screen.getByText(option.label)).toBeInTheDocument();
    });
  });
});
