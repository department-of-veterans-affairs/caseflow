import React from 'react';
import { shallow, mount } from 'enzyme';
import moment from 'moment-timezone';
import { invert } from 'lodash';


import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import TIMEZONES from 'constants/TIMEZONES';
import { COMMON_TIMEZONES } from 'app/constants/AppConstants';
import { timezones, roTimezones } from 'app/hearings/utils';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { timezoneDropdownStyles, timezoneStyles } from 'app/hearings/components/details/style';

// Set the test Constants
const defaultTime = '08:15';
const defaultRoTimezone = 'America/New_York'
const defaults = timezones(defaultTime, defaultRoTimezone);
const REGIONAL_OFFICE_TIMEZONES = roTimezones();

// Remove missing Regional Office zones from the count
const commonsCount = REGIONAL_OFFICE_TIMEZONES.filter((zone) => Object.values(TIMEZONES).includes(zone)).length;

// Reverse the commons array but don't mutate to move EST to the top for comparison
const commons = COMMON_TIMEZONES.slice().reverse();

describe('Timezone', () => {
  test('Matches snapshot with default props', () => {
    // Setup the test
    const tz = shallow(<Timezone time={HEARING_TIME_OPTIONS[0].value} roTimezone={defaultRoTimezone}/>);

    expect(tz).toMatchSnapshot();
    expect(tz.find('.cf-select__menu')).toHaveLength(0);

    // Test the dropdown component
    const dropdown = tz.find(SearchableDropdown);

    expect(dropdown).toHaveLength(1);
    expect(dropdown.prop('value')).toEqual(null);
    expect(dropdown.prop('styling')).toEqual(timezoneStyles(commonsCount));
    expect(dropdown.prop('options')).toHaveLength(Object.keys(TIMEZONES).length + 1);
  });

  test('Can set timezone', () => {
    // Setup the test
    const changeSpy = jest.fn();

    // Run the test
    const tz = mount(
      <Timezone
        name="tz"
        onChange={changeSpy}
        time={HEARING_TIME_OPTIONS[0].value}
        roTimezone={defaultRoTimezone}/>
    );
    const dropdown = tz.find(SearchableDropdown);

    // Initial state
    expect(tz.find('MenuList')).toHaveLength(0);
    expect(dropdown).toHaveLength(1);
    expect(dropdown.prop('value')).toEqual(null);

    // Open the menu
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    expect(tz.find('MenuList')).toHaveLength(1);

    // Change the value
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

    // // New State
    expect(tz.find('MenuList')).toHaveLength(0);
    expect(changeSpy).toHaveBeenCalledWith(defaults.options[1].value);
    expect(
      tz.find('.cf-select__single-value').first().
        text()
    ).toEqual(defaults.options[1].label);
    expect(tz).toMatchSnapshot();
  });

  test('Displays Regional Office timezones first', () => {
    // Run the test
    const tz = mount(<Timezone time={HEARING_TIME_OPTIONS[0].value} roTimezone={defaultRoTimezone}/>);
    const dropdown = tz.find(SearchableDropdown);

    // Assertions
    dropdown.prop('options').map((opt, index) => {
      // Ensure the first option is null
      if (index === 0) {
        expect(opt.value).toEqual(null);
        expect(opt.label).toEqual('');
      }

      // Ensure the common zones are the first 4
      if (index > 0 && index <= 3) {
        expect(opt.value).toEqual(commons[index - 1]);
      }

      // Ensure Regional Office timezones move to the top
      if (index > 3 && index < commonsCount) {
        expect(REGIONAL_OFFICE_TIMEZONES).toContain(opt.value);
      }

      // For all other cases ensure the timezone is one of the available and not a duplicate
      if (index > commonsCount) {
        expect(Object.values(TIMEZONES)).toContain(opt.value);
        expect(REGIONAL_OFFICE_TIMEZONES).not.toContain(opt.value);
        expect(COMMON_TIMEZONES).not.toContain(opt.value);
      }
    });
    expect(tz).toMatchSnapshot();
  });

  test('Respects required prop', () => {
    // Run the test
    const tz = mount(<Timezone required time={HEARING_TIME_OPTIONS[0].value} roTimezone={defaultRoTimezone}/>);

    // Assertions
    expect(tz.find('.cf-required')).toHaveLength(1);
    expect(tz).toMatchSnapshot();
  });

  test('Does not show required when ReadOnly', () => {
    // Run the test
    const tz = mount(<Timezone required readOnly time={HEARING_TIME_OPTIONS[0].value} roTimezone={defaultRoTimezone}/>);

    // Assertions
    expect(tz.find('.cf-required')).toHaveLength(0);
    expect(tz).toMatchSnapshot();
  });

  test('Dropdown displays correct times based on props time and roTimezone', () => {
    const time = HEARING_TIME_OPTIONS[0].value;
    const roTimezone = 'America/Los_Angeles';
    const dateTime = moment.tz(time, 'HH:mm', roTimezone)
    const roTzValueToLabelMapping = invert(TIMEZONES)

    const tz = mount(
      <Timezone time={time} roTimezone={roTimezone} />
    )
    const dropdown = tz.find(SearchableDropdown);

    dropdown.prop('options').map((opt) => {
      if (opt.value && opt.label && REGIONAL_OFFICE_TIMEZONES.includes(opt.value)) {
        const label = `${roTzValueToLabelMapping[opt.value]} (${moment(dateTime, 'HH:mm').tz(opt.value).format('h:mm A')})`
        expect(opt.label).toEqual(label)
      }
    })
    expect(tz).toMatchSnapshot();
  })
});
