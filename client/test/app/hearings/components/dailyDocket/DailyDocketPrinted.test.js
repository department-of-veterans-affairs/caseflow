import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import DailyDocketPrinted from '../../../../../../client/app/hearings/components/dailyDocket/DailyDocketPrinted';

const renderDailyDocketPrinted = (props) => {
  render(<DailyDocketPrinted {...props} />);
};

describe('DailyDocketPrinted', () => {
  it('renders tag VLJ when user is not a VSO employee', async () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { judgeFirstName: 'John', judgeLastName: 'Doe' },
    };

    renderDailyDocketPrinted(mockProps);
    expect(await screen.findByText(/VLJ:/)).toBeInTheDocument();
  });

  it('does not render tag VLJ when user is a VSO employee', () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: true },
      docket: { judgeFirstName: null, judgeLastName: null },
      disablePrompt: false,
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.queryByText(/VLJ:/)).not.toBeInTheDocument();
  });
});
