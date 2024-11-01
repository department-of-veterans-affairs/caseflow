import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import moment from 'moment-timezone';
import { invert } from 'lodash';


import { Timezone } from 'app/hearings/components/VirtualHearings/Timezone';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import TIMEZONES from 'constants/TIMEZONES';
import { COMMON_TIMEZONES } from 'app/constants/AppConstants';
import { timezones, roTimezones } from 'app/hearings/utils';

// Set the test Constants
const defaultTime = '08:15';
const defaultRoTimezone = 'America/New_York';
const defaults = timezones(defaultTime, defaultRoTimezone, '2025-01-01');
const REGIONAL_OFFICE_TIMEZONES = roTimezones();

// Remove missing Regional Office zones from the count
const commonsCount = REGIONAL_OFFICE_TIMEZONES.filter((zone) => Object.values(TIMEZONES).includes(zone)).length;

// Reverse the commons array but don't mutate to move EST to the top for comparison
const commons = COMMON_TIMEZONES.slice().reverse();

const hearingDayDate = '2025-01-01';

const changeSpy = jest.fn();

describe('Timezone', () => {
  test('Matches snapshot with default props', async () => {
    const timeZoneLength = Object.keys(TIMEZONES).length + 1;

    // Setup the test
    const {asFragment, container} = render(
    <Timezone
      time={HEARING_TIME_OPTIONS[0].value}
      roTimezone={defaultRoTimezone}/>
    );

    // Dropdown is closed
    expect(screen.queryAllByRole('listbox')).toHaveLength(0);
    expect(container.querySelector('.cf-select__menu')).not.toBeInTheDocument();

    // Find the dropdown
    const dropdown = screen.getByRole('combobox');
    expect(dropdown).toBeInTheDocument();
    expect(dropdown.value).toEqual('');

    // Open the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown'});
    expect(screen.queryAllByRole('listbox')).toHaveLength(1);

    // Dropdown is open
    expect(container.querySelector('.cf-select__menu')).toBeInTheDocument();

    const options = screen.getAllByRole('option');
    expect(options.length).toEqual(timeZoneLength);

    expect(asFragment()).toMatchSnapshot();
  });

  test('Can set timezone', () => {
    // Run the test
    const {asFragment, container} = render(
      <Timezone
        onChange={changeSpy}
        time={HEARING_TIME_OPTIONS[0].value}
        roTimezone={defaultRoTimezone}
        hearingDayDate={hearingDayDate}
      />
    );

    // Find the dropdown
    const dropdown = screen.getByRole('combobox');
    expect(dropdown).toBeInTheDocument();

    // Initial state, Dropdown is closed
     expect(screen.queryAllByRole('listbox')).toHaveLength(0);
     expect(container.querySelector('.cf-select__menu')).not.toBeInTheDocument();
     expect(dropdown.value).toEqual('');

    // Open the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    expect(screen.queryAllByRole('listbox')).toHaveLength(1);
    expect(container.querySelector('.cf-select__menu')).toBeInTheDocument();

    // Change the value
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'Enter' });

    // New State
    expect(container.querySelector('.cf-select__menu')).not.toBeInTheDocument();
    expect(changeSpy).toHaveBeenCalledWith(defaults.options[1].value);
    const hiddenInput = container.querySelector('[type="hidden"]');
    expect(hiddenInput).toHaveAttribute('value', defaults.options[1].value);

    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays Regional Office timezones first', () => {
    // Run the test
    const {asFragment, container} = render(
    <Timezone
      time={HEARING_TIME_OPTIONS[0].value}
      onChange={changeSpy}
      roTimezone={defaultRoTimezone}/>
    );

    // Open the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    expect(screen.queryAllByRole('listbox')).toHaveLength(1);

    // Ensure the first option is empty and the second exists
    let options = screen.getAllByRole('option');
    expect(options.length).toBeGreaterThan(0);
    expect(options[0].textContent).toEqual('');
    expect(options[1].textContent).
    toEqual(`Eastern Time (US & Canada)`);


    // Ensure the common zones are the first 4
    let hiddenInput = container.querySelector('[type="hidden"]');

    // 1st option
    fireEvent.click(options[1])
    expect(changeSpy).toHaveBeenCalledWith(defaults.options[1].value);
    expect(commons).toContain(hiddenInput.value);

    // Reopen the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    options = screen.getAllByRole('option');

    // Second click
    fireEvent.click(options[2]);
    expect(changeSpy).toHaveBeenCalledWith(defaults.options[2].value);
    hiddenInput = container.querySelector('[type="hidden"]');
    expect(commons).toContain(hiddenInput.value);

    // Reopen the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    options = screen.getAllByRole('option');

    // Third click
    fireEvent.click(options[3]);
    expect(changeSpy).toHaveBeenCalledWith(defaults.options[3].value);
    hiddenInput = container.querySelector('[type="hidden"]');
    expect(commons).toContain(hiddenInput.value);

    // Reopen the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    options = screen.getAllByRole('option');

    // Fourth click
    fireEvent.click(options[4]);
    expect(changeSpy).toHaveBeenCalledWith(defaults.options[4].value);
    hiddenInput = container.querySelector('[type="hidden"]');
    expect(commons).toContain(hiddenInput.value);

    // Reopen the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    options = screen.getAllByRole('option');

    // Ensure Regional Office timezones move to the top
    const optionTexts = options
      .map(option => option.textContent.trim())
      .filter(text => text !== '')
      .slice(0, commonsCount)
      .map(text => text.replace(/\s*\(.*?\)\s*/g, ''));

    // Map the option texts to their values by finding the key that contains the text
    const optionValues = optionTexts.map(text => {
      const matchedKey = Object.keys(TIMEZONES).find(key => key.includes(text));
      return TIMEZONES[matchedKey];
    });

    const sortedOptionValues = optionValues.slice().sort();
    const sortedRegionalOfficeTimezones = REGIONAL_OFFICE_TIMEZONES.slice().sort();
    expect(sortedOptionValues).toEqual(sortedRegionalOfficeTimezones);

    // For all other cases ensure the timezone is one of the available and not a duplicate
    const remainingOptions = options
      .map(option => option.textContent.trim())
      .filter(text => text !== '')
      .slice(commonsCount)
      .map(text => text.replace(/\s*\(.*?\)\s*/g, ''));

    const remainingOptionValues = remainingOptions.map(text => {
      const matchedKey = Object.keys(TIMEZONES).find(key => key.includes(text));
      return TIMEZONES[matchedKey];
    });

    remainingOptionValues.forEach(item => {
      expect(REGIONAL_OFFICE_TIMEZONES).not.toContain(item);
      expect(COMMON_TIMEZONES).not.toContain(item);
    });

    expect(asFragment()).toMatchSnapshot();
    // expect(tz).toMatchSnapshot();
  });

  test('Respects required prop', () => {
    // Run the test
    const {asFragment, container} = render(
      <Timezone
        required
        time={HEARING_TIME_OPTIONS[0].value}
        roTimezone={defaultRoTimezone}/>
      );

    expect(container.querySelector('.cf-required')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not show required when ReadOnly', () => {
    // Run the test
    const {asFragment, container} = render(
      <Timezone
        required
        readOnly
        time={HEARING_TIME_OPTIONS[0].value}
        roTimezone={defaultRoTimezone}/>
      );

    expect(container.querySelector('.cf-required')).not.toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Dropdown displays correct times based on props time and roTimezone', () => {
    const timeWithTimezone = HEARING_TIME_OPTIONS[0].value;
    const splitTimeString = timeWithTimezone.search('AM');
    const time = `${timeWithTimezone.slice(0, splitTimeString).trim()} am`;

    const roTimezone = 'America/Los_Angeles';
    const dateTime = moment.tz(`${hearingDayDate} ${time}`, 'YYYY-MM-DD h:mm a', roTimezone);
    const roTzValueToLabelMapping = invert(TIMEZONES);

    // Run the test
    const {asFragment} = render(
      <Timezone
        time={time}
        onChange={changeSpy}
        roTimezone={roTimezone}/>
      );

    expect( screen.getByRole('combobox')).toBeInTheDocument();

    // Open the menu
    fireEvent.keyDown(screen.getByRole('combobox'), { key: 'ArrowDown' });
    const options = screen.getAllByRole('option');

    const allOptions = options
    .map(option => option.textContent.trim())
    .filter(text => text !== '');

    const allOptionsRegex = allOptions.map(text => text.replace(/\s*\(.*?\)\s*/g, ''));

    const allOptionValues = allOptionsRegex.map(text => {
      const matchedKey = Object.keys(TIMEZONES).find(key => key.includes(text));
      return TIMEZONES[matchedKey];
    });

    allOptionValues.forEach(item => {
      if (REGIONAL_OFFICE_TIMEZONES.includes(item)) {
        const label = `${roTzValueToLabelMapping[item]} (${moment(dateTime, 'HH:mm').format('h:mm A')})`;
        allOptions.map(opt => {
          if (opt.value === item) {
            expect(opt.label).toEqual(label);
          }
        });
      }
    });
    expect(asFragment()).toMatchSnapshot();
  })
});
