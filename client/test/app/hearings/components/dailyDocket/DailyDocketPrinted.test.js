import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import DailyDocketPrinted from '../../../../../../client/app/hearings/components/dailyDocket/DailyDocketPrinted';

describe('DailyDocketPrinted', () => {
  it('renders tag VLS when user is not a VSO employee', async () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { judgeFirstName: 'John', judgeLastName: 'Doe' },
    };

    render(<DailyDocketPrinted {...mockProps} />);
    expect(await screen.queryByText(/VLJ:/)).toBeInTheDocument();
  });

  it('does not render tag VLJ when user is not a VSO employee', () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: true },
      docket: { judgeFirstName: null, judgeLastName: null },
      disablePrompt: false,
    };

    render(<DailyDocketPrinted {...mockProps} />);
    expect(screen.queryByText(/VLJ:/)).not.toBeInTheDocument();
  });
});
