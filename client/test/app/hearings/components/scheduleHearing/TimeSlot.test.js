import React from 'react';

import { TimeSlot } from 'app/hearings/components/scheduleHearing/TimeSlot';
import { render, fireEvent, screen } from '@testing-library/react';
import { roTimezones, setTimeSlots, formatTimeSlotLabel } from 'app/hearings/utils';
import { axe } from 'jest-axe';

import REGIONAL_OFFICE_INFORMATION from '../../../../../constants/REGIONAL_OFFICE_INFORMATION';
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

  return { container, utils, timeSlots };
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
      const zone = 'America/Los_Angeles';
      // TODO, NO! Just reach through into the setSlots methond and examine what comes back
      const { timeSlots, utils } = setup({ roTimezone: zone });

      const eightThirtyAmRoZone = moment.tz('8:30', 'HH:mm', zone);
      const threeThirtyPmEastern = moment.tz('15:30', 'HH:mm', 'America/New_York');

      // First slot is at 8:30am roTime or 9:00am roTime
      expect(timeSlots[0].time.isSame(eightThirtyAmRoZone, 'hour')).toEqual(true);

      // Last slot is at 3:30pm eastern or 4:00pm eastern if central
      expect(timeSlots[timeSlots.length - 1].time.isSame(threeThirtyPmEastern, 'hour')).toEqual(true);

      // Toggle back and forth, check that they're still correct
      toggleBackAndForth(utils);

      // First slot is at 8:30am roTime or 9:00am roTime
      expect(timeSlots[0].time.isSame(eightThirtyAmRoZone, 'hour')).toEqual(true);

      // Last slot is at 3:30pm eastern or 4:00pm eastern if central
      expect(timeSlots[timeSlots.length - 1].time.isSame(threeThirtyPmEastern, 'hour')).toEqual(true);
    });
    it('has correct custom dropdown options when the ro is in different timezones', () => {
      // Check that the dropdown times are correct
      // Toggle back and forth, check that they're still correct
      expect(true).toEqual(true);
    });
    // });
  });

  describe('schedules for the time selected when the ro is in different timezones', () => {
    it('schedules a hearing in different timezones', () => {});
    it('produces a hearing at the correct time in different timezones', () => {});
  });
})
;
