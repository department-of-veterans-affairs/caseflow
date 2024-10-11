import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ResetButton from 'app/caseDistribution/components/testPage/ResetButton';

describe('ResetButton', () => {
  const mockOnClick = jest.fn();

  beforeEach(() => {
    render(<ResetButton onClick={mockOnClick} loading={false} />);
  });

  it('renders correctly', () => {
    const button = screen.getByRole('button', { name: /Clear Ready-to-Distribute Appeals/i });
    expect(button).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const button = screen.getByRole('button', { name: /Clear Ready-to-Distribute Appeals/i });
    fireEvent.click(button);
    expect(mockOnClick).toHaveBeenCalledTimes(1);
  });

  it('shows loading state when loading prop is true', () => {
    render(<ResetButton onClick={mockOnClick} loading={true} />);
    const button = screen.getByRole('button', { name: /Clearing Ready-to-Distribute Appeals/i });
    expect(button).toBeInTheDocument();
  });
});
