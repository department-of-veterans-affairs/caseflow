import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';

import { UnscheduledNotes } from 'app/hearings/components/UnscheduledNotes';

describe('UnscheduledNotes', () => {
  const onChange = jest.fn();
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const inputText = 'Type notes here'
  const maxCharLimit = 1000
  const defaultProps = {
    updatedByCssId: 'VACOUSER',
    updatedAt: '2020-09-08T10:03:49.210-04:00',
    unscheduledNotes: inputText,
    onChange
  };

  it('renders correctly', () => {
    const { container } = render(<UnscheduledNotes {...defaultProps} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<UnscheduledNotes {...defaultProps} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('correctly calls onChange', async () => {
    const container = render(
      <UnscheduledNotes {...defaultProps} unscheduledNotes={''} />
    );

    const inputField = container.getByLabelText('Notes')

    await userEvent.type(inputField, inputText);

    // Calls onChange handler each time a key is pressed
    expect(onChange).toHaveBeenCalledTimes(inputText.length);
    expect(onChange).toHaveBeenLastCalledWith(inputText[inputText.length - 1]);
  });

  it('displays character limit info when notes is present', () => {
    render(<UnscheduledNotes {...defaultProps} />);

    const charLimitMessage = `${maxCharLimit - inputText.length} characters left`
    expect(screen.getByText(charLimitMessage)).toBeInTheDocument()
  });

  it('does not display textfield when readonly is passed as prop', () => {
    render(<UnscheduledNotes {...defaultProps} readonly/>);

    expect(screen.queryByLabelText('Notes')).not.toBeInTheDocument()
  })
})
