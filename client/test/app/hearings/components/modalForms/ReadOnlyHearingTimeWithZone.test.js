import React from 'react';

import { ReadOnlyHearingTimeWithZone } from 'app/hearings/components/modalForms/ReadOnlyHearingTimeWithZone';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { mount } from 'enzyme';
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
        const form = mount(
          <ReadOnlyHearingTimeWithZone
            hearingStartTime={hearingStartTime ?? null}
            timezone={timezone}
            onRender={jest.fn()}
          />
        );
        const zoneName = shortZoneName(timezone);
        expect(form).toMatchSnapshot();
        if (hearingStartTime === null) {
          expect(form.exists('ReadOnly')).toBe(false);
        } else {
          expect(form.exists('ReadOnly')).toBe(true);
          const dateTime = moment(hearingStartTime).tz(timezone, true);
          if (zoneName === 'Eastern') {
            expect(
              form.find(ReadOnly).prop('text')
            ).toEqual(`${dateTime.format('h:mm A')} ${zoneName}`);
          } else {
            expect(
              form.find(ReadOnly).prop('text')
            ).toEqual(
              `${dateTime.format('h:mm A')} ${zoneName} / ${moment(dateTime).tz('America/New_York').format('h:mm A')} Eastern`
            );
          }
        }
      })
    })
  });
});
