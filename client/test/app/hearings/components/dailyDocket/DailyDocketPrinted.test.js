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

  it('renders docket notes when user is a board employee', async () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { notes: 'There is a note here' }
    };

    renderDailyDocketPrinted(mockProps);
    expect(await screen.findByText(/Notes:/)).toBeInTheDocument();
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

  it('does not render docket notes when user is a nonBoardEmployee', async () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: true },
      docket: { notes: 'There is a note here' },
    };

    renderDailyDocketPrinted(mockProps);
    expect(await screen.queryByText(/Note:\s*This\s*is\s*a\s*note/)).not.toBeInTheDocument();
  });

  it('displays post meridiem time for DST time with scheduledInTimezone null', () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { scheduledFor: '06-17-2024' },
      hearings: [
        {
          scheduledTimeString: '3:30 PM Eastern Time (US & Canada)',
          scheduledInTimezone: null,
          regionalOfficeTimezone: 'America/New_York'
        }
      ]
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.getByText('3:30 PM EDT')).toBeInTheDocument();
  });

  it('displays post meridiem time for DST time with scheduledInTimezone provided', () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { scheduledFor: '06-17-2024' },
      hearings: [
        {
          scheduledFor: '2024-06-17T15:30:00.000-04:00',
          scheduledInTimezone: 'America/New_York',
        }
      ]
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.getByText('3:30 PM EDT')).toBeInTheDocument();
  });

  it('displays post meridiem time in winter with scheduledInTimezone null', () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { scheduledFor: '12-17-2024' },
      hearings: [
        {
          scheduledTimeString: '3:30 PM Eastern Time (US & Canada)',
          scheduledInTimezone: null,
          regionalOfficeTimezone: 'America/New_York'
        }
      ]
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.getByText('3:30 PM EST')).toBeInTheDocument();
  });

  it('displays post meridiem time in winter with scheduledInTimezone provided', () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { scheduledFor: '12-17-2024' },
      hearings: [
        {
          scheduledFor: '2024-12-17T15:30:00.000-05:00',
          scheduledInTimezone: 'America/New_York',
        }
      ]
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.getByText('3:30 PM EST')).toBeInTheDocument();
  });

  it('displays post meridiem time in summer with scheduledInTimezone null, ro timezone does not observe DST', () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { scheduledFor: '06-17-2024' },
      hearings: [
        {
          scheduledTimeString: '3:30 PM Hawaii',
          scheduledInTimezone: null,
          regionalOfficeTimezone: 'Pacific/Honolulu'
        }
      ]
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.getByText('3:30 PM HST')).toBeInTheDocument();
  });

  it('displays post meridiem time in summer with scheduledInTimezone provided, timezone does not observe DST', () => {
    const mockProps = {
      user: { userIsNonBoardEmployee: false },
      docket: { scheduledFor: '06-17-2024' },
      hearings: [
        {
          scheduledFor: '2024-06-17T15:30:00.000-10:00',
          scheduledInTimezone: 'Pacific/Honolulu',
        }
      ]
    };

    renderDailyDocketPrinted(mockProps);
    expect(screen.getByText('3:30 PM HST')).toBeInTheDocument();
  });
});
