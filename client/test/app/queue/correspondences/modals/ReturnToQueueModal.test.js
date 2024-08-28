import React from 'react';
import ReturnToQueueModal from "../../../../../app/queue/correspondence/intake/components/ReturnToQueueModal";
import { fireEvent, render, screen } from '@testing-library/react';

const renderReturnToQueueModal = () => {
  render(
      <ReturnToQueueModal onCancel={jest.fn()} handleContinueIntakeLater={jest.fn()} handleCancelIntake={jest.fn()}/>
  );
};

describe('ReturnToQueueModal rendering', () => {
  it('renders the return to queue modal', () => {
    renderReturnToQueueModal();

    expect(screen.getByText('Return To Queue')).toBeInTheDocument();
    expect(screen.getByText('Select whether to cancel the intake of this mail package or resume the intake process at a later date.')).toBeInTheDocument();
    expect(screen.getByText('Cancel intake')).toBeInTheDocument();
    expect(screen.getByText('Continue intake at a later date')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Close' })).toBeEnabled();
    expect(screen.getByRole('button', { name: 'Confirm' })).toBeDisabled();
  });

  it('Radio selection', () => {
    renderReturnToQueueModal();

    expect(screen.getByRole('button', { name: 'Confirm' })).toBeDisabled();

    const option1 = screen.getByLabelText('Cancel intake');
    const option2 = screen.getByLabelText('Continue intake at a later date');

    expect(option1.checked).toBe(false);
    expect(option2.checked).toBe(false);

    fireEvent.click(option1);
    expect(option1.checked).toBe(true);
    expect(option2.checked).toBe(false);
    expect(screen.getByRole('button', { name: 'Confirm' })).toBeEnabled();

    fireEvent.click(option2);
    expect(option1.checked).toBe(false);
    expect(option2.checked).toBe(true);
    expect(screen.getByRole('button', { name: 'Confirm' })).toBeEnabled();
    expect(screen.getByRole('alert')).toBeInTheDocument();
    expect(screen.getByRole('alert')).toHaveTextContent('Saving the intake form to continue it at a later date will resume the intake form at step three of the process');
  });


});
