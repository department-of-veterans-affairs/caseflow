import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import CancelReviewTranscriptTaskModal from 'app/queue/components/CancelReviewTranscriptTaskModal';

describe('CancelReviewTranscriptTaskModal', () => {
  const closeModal = jest.fn();

  const defaultProps = {
    taskId: '1000',
    closeModal
  };

  it('renders correctly', () => {
    const { container } = render(<CancelReviewTranscriptTaskModal {...defaultProps} />);

    expect(container).toMatchSnapshot();
  });

  it('displays the default page elements with default props', () => {
    render(
      <CancelReviewTranscriptTaskModal {...defaultProps} />
    );

    const textarea = screen.getByRole('textbox');

    expect(screen.getAllByText('Cancel task').length).toBe(2);
    expect(screen.getByText("Cancelling this task will permanently remove it from the case's active tasks.")).
      toBeInTheDocument();
    expect(screen.getByText('Please provide context and instructions for this action')).
      toBeInTheDocument();
    expect(textarea.value).toBe('');
  });

  it('the submit button is enabled when fields filled out', async () => {
    render(
      <CancelReviewTranscriptTaskModal {...defaultProps} />
    );

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
