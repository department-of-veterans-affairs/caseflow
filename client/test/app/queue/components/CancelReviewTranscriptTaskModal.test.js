import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import CancelReviewTranscriptTaskModal from 'app/queue/components/CancelReviewTranscriptTaskModal';

describe('CancelReviewTranscriptTaskModal', () => {
  const closeModal = jest.fn();

  const defaultProps = {
    taskId: '1000',
    closeModal
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const getCancelReviewTranscriptTaskModal = (store) => render(
    <Provider store={store}>
      <CancelReviewTranscriptTaskModal {...defaultProps} />
    </Provider>
  );

  it('renders correctly', () => {
    const store = getStore();
    const { container } = getCancelReviewTranscriptTaskModal(store);

    expect(container).toMatchSnapshot();
  });

  it('displays the default page elements with default props', () => {
    const store = getStore();

    getCancelReviewTranscriptTaskModal(store);

    const textarea = screen.getByRole('textbox');

    expect(screen.getAllByText('Cancel task').length).toBe(2);
    expect(screen.getByText("Cancelling this task will permanently remove it from the case's active tasks.")).
      toBeInTheDocument();
    expect(screen.getByText('Please provide context and instructions for this action')).
      toBeInTheDocument();
    expect(textarea.value).toBe('');
  });

  it('the submit button is enabled when fields filled out', async () => {
    const store = getStore();

    getCancelReviewTranscriptTaskModal(store);

    expect(screen.getByRole('button', { name: 'Cancel task' })).
      toBeDisabled();

    const textarea = screen.getByRole('textbox');

    userEvent.type(textarea, 'Test note');

    await waitFor(() => {
      expect(screen.getByRole('button', { name: 'Cancel task' })).
        toBeEnabled();
    });
  });
});
