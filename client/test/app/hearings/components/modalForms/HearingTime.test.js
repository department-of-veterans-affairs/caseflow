import React from 'react';

import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import { mount } from 'enzyme';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import { COMMON_TIMEZONES } from 'app/constants/AppConstants';
import TIMEZONES from 'constants/TIMEZONES';

const [timezoneLabel] = Object.keys(TIMEZONES).filter((zone) => TIMEZONES[zone] === COMMON_TIMEZONES[3]);

const hearingDayDate = '2025-01-01';

describe('HearingTime', () => {
  // Ignore warnings about SearchableDropdown
  jest.spyOn(console, 'error').mockReturnValue();

  test('Matches snapshot with default props when passed in', () => {
    const form = mount(<HearingTime hearingDayDate={hearingDayDate} />);

    expect(form).toMatchSnapshot();

    const checkedRadio = form.find('input').find({ checked: true });

    // A single input is checked by default, and it's the "Other" radio
    expect(checkedRadio.exists()).toBe(true);
    expect(checkedRadio.exists({ value: 'Other' })).toBe(true);

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
    const hearingTime = mount(
      <HearingTime
        enableZone
        value={HEARING_TIME_OPTIONS[0].value}
        hearingDayDate={hearingDayDate}
      />);

    // Assertions
    expect(hearingTime).toMatchSnapshot();
    expect(hearingTime.find('Select').prop('value').label).toContain(timezoneLabel);
  });

  test('Matches snapshot when other time is not selected', () => {
    const form = mount(
      <HearingTime
        enableZone
        value="12:30 PM Eastern Time (US & Canada)"
        hearingDayDate={hearingDayDate}
      />);

    expect(form).toMatchSnapshot();

    expect(form.find('input').exists({ checked: true, value: '12:30 PM Eastern Time (US & Canada)' })).toBe(
      true
    );
  });

  test('Matches snapshot when other time is selected', () => {
    const selectedTime = '1:45 PM Eastern Time (US & Canada)';
    const option = HEARING_TIME_OPTIONS.find(({ value }) => value === selectedTime);

    const form = mount(<HearingTime value={selectedTime} hearingDayDate={hearingDayDate} />);

    expect(form).toMatchSnapshot();

    // Expect "Other" radio to be checked
    expect(form.find('input').exists({ checked: true, value: 'Other' })).toBe(true);

    // Expect dropdown to be populated with correct time
    expect(form.exists('SearchableDropdown')).toBe(true);
    expect(form.find('Select').exists({ value: option })).toBe(true);
  });

  test('Matches snapshot when readonly prop is set', () => {
    const form = mount(<HearingTime hearingDayDate={hearingDayDate} />);

    expect(form).toMatchSnapshot();

    expect(form.find('select').every({ disabled: true })).toBe(true);
  });
});
