import React from 'react';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import HEARING_TIME_OPTIONS from 'constants/HEARING_TIME_OPTIONS';
import { COMMON_TIMEZONES } from 'app/constants/AppConstants';
import TIMEZONES from 'constants/TIMEZONES';

const [timezoneLabel] = Object.keys(TIMEZONES).filter((zone) => TIMEZONES[zone] === COMMON_TIMEZONES[3]);

const hearingDayDate = '2025-01-01';

describe('HearingTime', () => {
  // Ignore warnings about SearchableDropdown
  jest.spyOn(console, 'error').mockReturnValue();

  test('Matches snapshot with default props when passed in', () => {
    const {asFragment} = render(<HearingTime />);

    expect(asFragment()).toMatchSnapshot();

    const checkedRadio = screen.getByRole('radio', { name: 'Other'})

    // A single input is checked by default, and it's the "Other" radio
    expect(checkedRadio).toBeInTheDocument();
    expect(checkedRadio.value).toBe('other');
    expect(checkedRadio).toBeChecked();

    const dropdown = screen.getByRole('combobox');

    // The select field is not disabled by default (meaning the "Other")
    // radio is checked
    expect(dropdown).toBeInTheDocument();
    expect(dropdown).not.toBeDisabled();

    // Expect the naming of forms to match expected
    const radios = screen.getAllByRole('radio');
    expect(radios).toHaveLength(3);
  });

  test('Matches snapshot when enableZone is true', async () => {
    // Run the test
    const {asFragment} = render(<HearingTime enableZone value={HEARING_TIME_OPTIONS[0].value} />);

    // Assertions
    expect(asFragment()).toMatchSnapshot();

    const textToMatch = timezoneLabel;
    const regexPattern = textToMatch.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(regexPattern, 'i');

    await waitFor(() => {
      const elements = screen.getAllByText(regex);
      expect(elements.length).toBeGreaterThan(0); // Ensure we have found at least one element
    });

    const founcElements = screen.getAllByText(regex);
    founcElements.forEach(element => {
      expect(element).toBeInTheDocument();
    });
  });

  test('Matches snapshot when other time is not selected', () => {
    const {asFragment} = render(<HearingTime value="12:30" />);

    expect(asFragment()).toMatchSnapshot();

    const dropdown = screen.queryByRole('combobox');
    expect(dropdown).toBeNull();

    const radios = screen.getAllByRole('radio');
    const radioValues = radios.map(radio => radio.value);
    expect(radios).toHaveLength(3);
    expect(radioValues).toContain('12:30');
    expect(radioValues).toContain('08:30');
    expect(radioValues).toContain('other');
  });

  test('Matches snapshot when other time is selected', async () => {
    const selectedTime = '13:45';
    const option = HEARING_TIME_OPTIONS.find(({ value }) => value === selectedTime);

    const {asFragment} = render(<HearingTime value={selectedTime} />);

    expect(asFragment()).toMatchSnapshot();

    // Expect "Other" radio to be checked
    const checkedRadio = screen.getByRole('radio', { name: 'Other'});
    expect(checkedRadio).toBeChecked();

    // Expect dropdown to be populated with correct time
    const dropdown = screen.getByRole('combobox');
    expect(dropdown).toBeInTheDocument();

    userEvent.type(dropdown, ' ');

    // Wait for the options to appear and get them
    const listbox = await screen.findByRole('listbox');
    const options = within(listbox).getAllByRole('option');
    const isPresent = options.some(opt => opt.textContent === option.label);
    expect(isPresent).toBe(true);
  });

  test('Matches snapshot when readonly prop is set', () => {
    const {asFragment} = render(<HearingTime readOnly={true}/>);

    expect(asFragment()).toMatchSnapshot();

    // Check if all select elements are disabled
    const select = screen.queryByRole('combobox');
    expect(select).toBeNull();
  });
});
