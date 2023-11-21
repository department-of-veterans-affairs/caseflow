import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import DailyDocketPrinted from '../../../../../../client/app/hearings/components/dailyDocket/DailyDocketPrinted';

describe('DailyDocketPrinted', () => {
  it('renders judge name when user is not a VSO employee and judge name is present', () => {
    const mockProps = {
      user: { userVsoEmployee: false },
      docket: { judgeFirstName: 'John', judgeLastName: 'Doe' },
      hearings: {},
      disablePrompt: false,
    };

    render(<DailyDocketPrinted {...mockProps} />);
    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });

  it('does not render judge name when judge first name and last name are null', () => {
    const mockProps = {
      user: { userVsoEmployee: true },
      docket: { judgeFirstName: null, judgeLastName: null },
      disablePrompt: false,
    };

    render(<DailyDocketPrinted {...mockProps} />);
    expect(screen.queryByText('VLJ:')).not.toBeInTheDocument();
  });
});
