import React from 'react';
import { shallow, mount } from 'enzyme';
import moment from 'moment-timezone';
import Select from 'react-select';

import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import TIMEZONES from 'constants/TIMEZONES';
import { COMMON_TIMEZONES } from 'app/constants/AppConstants';
import { timezones, roTimezones } from 'app/hearings/utils';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { timezoneDropdownStyles, timezoneStyles } from 'app/hearings/components/details/style';

// Set the test Constants
const defaultTime = '08:15';
const defaults = timezones(defaultTime);
const REGIONAL_OFFICE_TIMEZONES = roTimezones();
const commonsCount = REGIONAL_OFFICE_TIMEZONES.length;

describe('Timezone', () => {
  test('Matches snapshot with default props', () => {
    // Setup the test
    const tz = shallow(<Timezone time={HEARING_TIME_OPTIONS[0].value} />);

    expect(tz).toMatchSnapshot();
    expect(tz.find('.Select-menu')).toHaveLength(0);

    // Test the dropdown component
    const dropdown = tz.find(SearchableDropdown);

    expect(dropdown).toHaveLength(1);
    expect(dropdown.prop('value')).toEqual(null);
    expect(dropdown.prop('styling')).toEqual(timezoneStyles(commonsCount));
    expect(dropdown.prop('dropdownStyling')).toEqual(timezoneDropdownStyles(commonsCount));
    expect(dropdown.prop('options')).toHaveLength(Object.keys(TIMEZONES).length);
  });

  test('Can set timezone', () => {
    // Setup the test
    const changeSpy = jest.fn();

    // Run the test
    const tz = mount(<Timezone onChange={changeSpy} time={HEARING_TIME_OPTIONS[0].value} />);
    const dropdown = tz.find(SearchableDropdown);

    // Initial state
    expect(tz.find('.Select-menu')).toHaveLength(0);
    expect(dropdown).toHaveLength(1);
    expect(dropdown.prop('value')).toEqual(null);

    // Open the menu
    dropdown.find('.Select-control').simulate('keyDown', { keyCode: 40 });
    expect(tz.find('.Select-menu')).toHaveLength(1);

    // Change the value
    tz.find('input').simulate('change', { target: { value: defaults.options[1].value } });
    dropdown.find('.Select-control').simulate('keyDown', { keyCode: 13 });

    // // New State
    expect(tz.find('.Select-menu')).toHaveLength(0);
    expect(changeSpy).toHaveBeenCalledWith(defaults.options[1].value);
    expect(
      tz.
        find('#react-select-2--value-item').
        first().
        text()
    ).toEqual(defaults.options[1].label);
    expect(tz).toMatchSnapshot();
  });

  test('Displays Regional Office timezones first', () => {
    // Run the test
    const tz = mount(<Timezone time={HEARING_TIME_OPTIONS[0].value} />);
    const dropdown = tz.find(SearchableDropdown);

    // Assertions
    dropdown.prop('options').map((opt, index) => {
      // Ensure the common zones are the first 4
      if (index <= 3) {
        expect(opt.value).toEqual(COMMON_TIMEZONES[index]);
      }

      expect(Object.values(TIMEZONES)).toContain(opt.value);
    });
  });
});
