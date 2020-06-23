import React from 'react';

import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS.json';
import { mount } from 'enzyme';

describe('HearingTime', () => {
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
    console.log(form.debug());
    expect(form.find('Select').exists({ value: option })).toBe(true);
  });

  test('Matches snapshot when readonly prop is set', () => {
    const form = mount(<HearingTime />);

    expect(form).toMatchSnapshot();

    expect(form.find('select').every({ disabled: true })).toBe(true);
  });
});
