import React from 'react';

import { TimeSlot } from 'app/hearings/components/scheduleHearing/TimeSlot';
import { render, fireEvent, screen } from '@testing-library/react';
import { roTimezones, setTimeSlots, formatTimeSlotLabel, hearingTimeOptsWithZone } from 'app/hearings/utils';
import { axe } from 'jest-axe';

import REGIONAL_OFFICE_INFORMATION from '../../../../../constants/REGIONAL_OFFICE_INFORMATION';
import HEARING_TIME_OPTIONS from '../../../../../constants/HEARING_TIME_OPTIONS';

import moment from 'moment-timezone/moment-timezone';

const emptyHearings = [];
const defaultRoCode = 'RO39';
const defaultProps = {
  // Denver
  ro: defaultRoCode,
  roTimezone: REGIONAL_OFFICE_INFORMATION[defaultRoCode].timezone,
  hearings: emptyHearings,
  fetchScheduledHearings: jest.fn(),
  onChange: jest.fn()
};

const setup = (props = {}) => {
  const utils = render(<TimeSlot {...defaultProps} {...props} />);
  const container = utils.container;
  const timeSlots = setTimeSlots(
    props.hearings || defaultProps.hearings,
    props.ro || defaultProps.ro,
    props.roTimezone || defaultProps.roTimezone,
  );
  const dropdownItems = hearingTimeOptsWithZone(
    HEARING_TIME_OPTIONS,
    props.roTimezone || defaultProps.roTimezone,
    props.roTimezone || defaultProps.roTimezone,
  );

  return { container, utils, timeSlots, dropdownItems };
};

const toggleToCustomLink = (utils) => utils.queryByText('Choose a custom time');
const toggleToSlotsLink = (utils) => utils.queryByText('Choose a time slot');

const toggleTo = ({ toSlots, utils }) => {
  const toggleLink = toSlots ? toggleToSlotsLink(utils) : toggleToCustomLink(utils);

  if (toggleLink) {
    fireEvent.click(toggleLink);
  }
};

const toggleToSlots = (utils) => toggleTo({ toSlots: true, utils });
const toggleToCustom = (utils) => toggleTo({ toSlots: false, utils });
const toggleBackAndForth = (utils) => {
  if (toggleToCustomLink(utils)) {
    toggleToCustom(utils);
    toggleToSlots(utils);
  }
  if (toggleToSlots(utils)) {
    toggleToSlots(utils);
    toggleToCustom(utils);
  }
};

const firstAndLastSlotsAreCorrect = (ro, timeSlots) => {
  if (ro.label === 'Central') {
    const nineAmRoZone = moment.tz('09:00', 'HH:mm', ro.timezone);
    const fourPmEastern = moment.tz('16:00', 'HH:mm', 'America/New_York');

    // First slot is at 8:30am roTime
    expect(timeSlots[0].time.isSame(nineAmRoZone, 'hour')).toEqual(true);
    // Last slot is at 3:30pm eastern
    expect(timeSlots[timeSlots.length - 1].time.isSame(fourPmEastern, 'hour')).toEqual(true);
  }
  if (ro.label !== 'Central') {
    const eightThirtyAmRoZone = moment.tz('8:30', 'HH:mm', ro.timezone);
    const threeThirtyPmEastern = moment.tz('15:30', 'HH:mm', 'America/New_York');

    // First slot is at 8:30am roTime
    expect(timeSlots[0].time.isSame(eightThirtyAmRoZone, 'hour')).toEqual(true);
    // Last slot is at 3:30pm eastern
    expect(timeSlots[timeSlots.length - 1].time.isSame(threeThirtyPmEastern, 'hour')).toEqual(true);
  }
};
const firstLastAndCountOfDropdownItemsCorrect = (ro, dropdownItems) => {
  const firstLabel = formatTimeSlotLabel(moment.tz('8:15', 'HH:mm', ro.timezone).tz('America/New_York').
    format('HH:mm'), ro.timezone);
  // const lastLabel = formatTimeSlotLabel('10:30', ro.timezone);

  expect(dropdownItems[0].label).toEqual(firstLabel);

};

describe('TimeSlot', () => {
  describe('has correct visual elements', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = setup();
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('should have 1 button for each time slot and 1 button to change to custom time', () => {
      const { utils, timeSlots } = setup();

      expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
      expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
      expect(document.getElementsByClassName('time-slot-container')).toHaveLength(2);
    });

    it('changes between custom and pre-defined times when button link clicked', () => {
      const { utils, timeSlots } = setup();

      // Click the toggle
      fireEvent.click(screen.getByText('Choose a custom time'));

      // Check that the correct elements are displayed
      expect(utils.getAllByRole('button')).toHaveLength(1);
      expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
      expect(document.getElementsByClassName('time-slot-container')).toHaveLength(0);

      // Click the toggle
      fireEvent.click(screen.getByText('Choose a time slot'));

      // Check that the correct types of elements are displayed
      expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
      expect(document.getElementsByClassName('time-slot-button-toggle')).toHaveLength(1);
      expect(document.getElementsByClassName('time-slot-container')).toHaveLength(2);
    });

    it('selects a time slot when clicked', () => {
      const { utils, timeSlots } = setup();

      // Click 2 different hearing times
      fireEvent.click(screen.getByText(formatTimeSlotLabel('10:30', defaultProps.roTimezone)));
      fireEvent.click(screen.getByText(formatTimeSlotLabel('11:30', defaultProps.roTimezone)));

      // Check that the correct elements are displayed
      expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
      expect(document.getElementsByClassName('time-slot-button-selected')).toHaveLength(1);
    });
  });

  describe('has correct time options in multiple timezones', () => {

    /*
    const regionalOfficeCodes = [
      // New York, Eastern time
      'RO06',
      // DC, Eastern time, central RO is special
      'C',
      // St. Paul, Central time
      'RO76',
      // Denver, Mountain time
      'RO39',
      // Oakland, Pacific time
      'RO43',
    ];
    const timezones = regionalOfficeCodes.map((roCode) => REGIONAL_OFFICE_INFORMATION[roCode]);

    timezones.map((zone) => {
      */

    it('has correct slot times when the ro is in different timezones', () => {
      const ro = { timezone: 'America/Los_Angeles' };
      const { timeSlots, utils } = setup({ roTimezone: ro.timezone });

      // Sanity check, but also remove linting problems because expects are in sub-functions
      expect(timeSlots.length > 0).toEqual(true);
      firstAndLastSlotsAreCorrect(ro, timeSlots);

      // Toggle back and forth, check that they're still correct
      toggleBackAndForth(utils);
      firstAndLastSlotsAreCorrect(ro, timeSlots);
    });

    it('has correct custom dropdown options when the ro is in different timezones', () => {
      const ro = { timezone: 'America/Los_Angeles' };
      const { dropdownItems, utils } = setup({ roTimezone: ro.timezone });

      toggleToCustom(utils);
      // Check that the dropdown times are correct
      expect(dropdownItems.length > 0).toEqual(true);
      firstLastAndCountOfDropdownItemsCorrect(ro, dropdownItems);
      // Toggle back and forth, check that they're still correct
      toggleBackAndForth(utils);
      firstLastAndCountOfDropdownItemsCorrect(ro, dropdownItems);
    });
    // });
  });

  describe('schedules for the time selected when the ro is in different timezones', () => {
    it('schedules a hearing in different timezones', () => {});
    it('produces a hearing at the correct time in different timezones', () => {});
  });
})
;
