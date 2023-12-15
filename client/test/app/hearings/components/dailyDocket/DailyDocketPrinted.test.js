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
      user: { userIsBoardHearingsEmployee: true },
      docket: { judgeFirstName: 'John', judgeLastName: 'Doe' },
    };

    renderDailyDocketPrinted(mockProps);
    expect(await screen.findByText(/VLJ:/)).toBeInTheDocument();
  });

  it('renders docket notes when user is a board employee', async () => {
    const mockProps = {
      user: { userIsBoardHearingsEmployee: true },
      docket: { notes: 'There is a note here' }
    };

    renderDailyDocketPrinted(mockProps);
    expect(await screen.findByText(/Notes:/)).toBeInTheDocument();
  });

  it('does not render tag VLJ when user is a VSO employee', () => {
    const mockProps = {
      user: { userIsBoardHearingsEmployee: false },
      docket: { judgeFirstName: null, judgeLastName: null },
      disablePrompt: false,
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.queryByText(/VLJ:/)).not.toBeInTheDocument();
  });

  it('does not render docket notes when user is not a Board employee', async () => {
    const mockProps = {
      user: { userIsBoardHearingsEmployee: false },
      docket: { notes: 'There is a note here' },
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.queryByText(/Note:\s*This\s*is\s*a\s*note/)).not.toBeInTheDocument();
  });
});
