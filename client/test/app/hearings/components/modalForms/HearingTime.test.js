import React from 'react';

import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import { ReadOnly } from 'app/hearings/components/details/ReadOnly';
import { mount } from 'enzyme';
import moment from 'moment-timezone/moment-timezone';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import { COMMON_TIMEZONES } from 'app/constants/AppConstants';
import TIMEZONES from 'constants/TIMEZONES';
import { shortZoneName } from 'app/hearings/utils';

const [timezoneLabel] = Object.keys(TIMEZONES).filter((zone) => TIMEZONES[zone] === COMMON_TIMEZONES[3]);

describe('HearingTime', () => {
  // Ignore warnings about SearchableDropdown
  jest.spyOn(console, 'error').mockReturnValue();

  test('Matches snapshot with default props when passed in', () => {
    const form = mount(<HearingTime />);

    expect(form).toMatchSnapshot();

    const checkedRadio = form.find('input').find({ checked: true });

    // A single input is checked by default, and it's the "Other" radio
    expect(checkedRadio.exists()).toBe(true);
    expect(checkedRadio.exists({ value: 'other' })).toBe(true);

    const dropdown = form.find('Select');

    // The select field is not disabled by default (meaning the "Other")
    // radio is checked
    expect(dropdown.exists()).toBe(true);
    expect(dropdown.exists({ disabled: false })).toBe(true);

    // Expect the naming of forms to match expected
    expect(form.exists({ name: 'hearingTime0' })).toBe(true);
    expect(form.exists({ name: 'optionalHearingTime0' })).toBe(true);
  });

  test('Matches snapshot when enableZone is true', () => {
    // Run the test
    const hearingTime = mount(<HearingTime enableZone value={HEARING_TIME_OPTIONS[0].value} />);

    // Assertions
    expect(hearingTime).toMatchSnapshot();
    expect(hearingTime.find('Select').prop('value').label).toContain(timezoneLabel);
  });

  test('Matches snapshot when other time is not selected', () => {
    const form = mount(<HearingTime value="12:30" />);

    expect(form).toMatchSnapshot();

    expect(form.exists('SearchableDropdown')).toBe(false);
    expect(form.find('input').exists({ checked: true, value: '12:30' })).toBe(
      true
    );
  });

  test('Matches snapshot when other time is selected', () => {
    const selectedTime = '13:45';
    const option = HEARING_TIME_OPTIONS.find(({ value }) => value === selectedTime);

    const form = mount(<HearingTime value={selectedTime} />);

    expect(form).toMatchSnapshot();

    // Expect "Other" radio to be checked
    expect(form.find('input').exists({ checked: true, value: 'other' })).toBe(true);

    // Expect dropdown to be populated with correct time
    expect(form.exists('SearchableDropdown')).toBe(true);
    expect(form.find('Select').exists({ value: option })).toBe(true);
  });

  test('Matches snapshot when readonly prop is set', () => {
    const form = mount(<HearingTime />);

    expect(form).toMatchSnapshot();

    expect(form.find('select').every({ disabled: true })).toBe(true);
  });

  test('Displays Readonly hearing time when hearingStartTime is passed as prop', () => {
    const hearingStartTimes = [
      '2021-07-29T08:30:00-04:00',
      '2021-07-30T12:30:00-04:00',
      null
    ];

    hearingStartTimes.forEach((hearingStartTime) => 
      const timezones = [
        'America/New_York',
        'America/Los_Angeles',
        'America/Denver',
        'America/Chicago',
        'America/Indiana/Indianapolis'
      ];

      timezones.forEach((timezone) => {
        const form = mount(
          <HearingTime
            hearingStartTime={hearingStartTime}
            localZone={timezone}
            onChange={jest.fn()}
          />
        );
        const zoneName = shortZoneName(timezone);
        expect(form).toMatchSnapshot();
        if (hearingStartTime === null) {
          expect(form.exists('SearchableDropdown')).toBe(true);
          expect(form.exists('ReadOnly')).toBe(false);
        } else {
          expect(form.exists('SearchableDropdown')).toBe(false);
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
