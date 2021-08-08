import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import moment from 'moment-timezone';
import { shortZoneName } from 'app/hearings/utils';

import { DocketStartTimes } from 'app/hearings/components/DocketStartTimes';

describe('DocketStartTimes', () => {
  const defaultProps = {
    roTimezone: null,
    hearingStartTime: null,
    setSlotCount: jest.fn(),
    setHearingStartTime: jest.fn()
  };

  const renderComponent = (props = {}) => render(
    <DocketStartTimes {...defaultProps} {...props}>
    </DocketStartTimes>
  );

  test('Matches snapshot with default props', () => {
    const { container } = renderComponent()

    expect(container).toMatchSnapshot();

    expect(screen.getByText('Available Times')).toBeInTheDocument();
    expect(container).toMatchSnapshot();
  });

  test('Passes a11y testing', async () => {
    const { container } = renderComponent()

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('Displays radio buttons according to RO timezone', () => {
    const timezones = [
      'America/New_York',
      'America/Los_Angeles',
      'America/Denver',
      'America/Chicago',
      'America/Indiana/Indianapolis'
    ];

    timezones.forEach((timezone) => {
      test(`for timezone (${timezone})`, () => {
        renderComponent({ roTimezone: timezone });
        expect(screen.getByText('Available Times')).toBeInTheDocument();

        const zoneName = shortZoneName(timezone);

        if (zoneName === 'Eastern') {
          const fullDayLabel = 'Full-Day AM & PM (10 slots at 8:30 AM & 12:30 PM Eastern)';
          const halfDayAmLabel = 'Half-Day AM (5 slots at 8:30 AM Eastern)';
          const halfDayPmLabel = 'Half-Day PM (5 slots at 12:30 PM Eastern)';

          expect(screen.getByText(fullDayLabel)).toBeInTheDocument();
          expect(screen.getByText(halfDayAmLabel)).toBeInTheDocument();
          expect(screen.getByText(halfDayPmLabel)).toBeInTheDocument()
        } else {
          const amTimeInEastern =
            moment(moment.tz('08:30', 'h:mm A', timezone)).tz('America/New_York').
              format('h:mm A');
          const pmTimeInEastern =
            moment(moment.tz('12:30', 'h:mm A', timezone)).tz('America/New_York').
              format('h:mm A');
          const fullDayLabel = `Full-Day AM & PM (10 slots at 8:30 AM & 12:30 PM ${zoneName})`;
          const halfDayAmLabel = `Half-Day AM (5 slots at 8:30 AM ${zoneName} / ${amTimeInEastern} Eastern)`;
          const halfDayPmLabel = `Half-Day PM (5 slots at 12:30 PM ${zoneName} / ${pmTimeInEastern} Eastern)`;

          expect(screen.getByText(fullDayLabel)).toBeInTheDocument();
          expect(screen.getByText(halfDayAmLabel)).toBeInTheDocument();
          expect(screen.getByText(halfDayPmLabel)).toBeInTheDocument();
        }
      })
    })
  });
});
