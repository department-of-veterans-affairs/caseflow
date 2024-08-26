import React from 'react';

import { ReadOnlyHearingTimeWithZone } from 'app/hearings/components/modalForms/ReadOnlyHearingTimeWithZone';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';

import { render, screen } from '@testing-library/react';
import moment from 'moment-timezone/moment-timezone';
import { shortZoneName } from 'app/hearings/utils';

describe('ReadOnlyHearingTimeWithZone', () => {
  // Ignore warnings about SearchableDropdown
  test('Displays readonly time when hearingStartTime prop has value', () => {
    const startTimes = [
      '08:30',
      '12:30',
      null
    ];

    startTimes.forEach((startTime) => {
      const timezones = [
        'America/New_York',
        'America/Los_Angeles',
        'America/Denver',
        'America/Chicago',
        'America/Indiana/Indianapolis'
      ];

      timezones.forEach((timezone) => {
        const hearingStartTime = moment(startTime).tz(timezone).format('HH:mm')
        const {asFragment} = render(
          <ReadOnlyHearingTimeWithZone
            hearingStartTime={hearingStartTime ?? null}
            timezone={timezone}
            onRender={jest.fn()}
          />
        );
        const zoneName = shortZoneName(timezone);

        expect(asFragment()).toMatchSnapshot();

        if (hearingStartTime === null) {
          expect(screen.queryByText('Hearing Time')).toBeNull();
        } else {
          const hearingTimeElements = screen.queryAllByText('Hearing Time');
          expect(hearingTimeElements).not.toHaveLength(0);
          const dateTime = moment(hearingStartTime).tz(timezone, true);
          if (zoneName === 'Eastern') {
            const expectedText = `${dateTime.format('h:mm A')} ${zoneName}`;
            const textElements = screen.queryAllByText(expectedText);
            expect(textElements).not.toHaveLength(0);
          } else {
            const expectedText = `${dateTime.format('h:mm A')} ${zoneName} / ${moment(dateTime).tz('America/New_York').format('h:mm A')} Eastern`;
            const textElements = screen.queryAllByText(expectedText);
            expect(textElements).not.toHaveLength(0);
          }
        }
      })
    })
  });
});
