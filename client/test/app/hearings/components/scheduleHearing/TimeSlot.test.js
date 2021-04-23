import React from 'react';

import { TimeSlot } from 'app/hearings/components/scheduleHearing/TimeSlot';
import { render, fireEvent, screen } from '@testing-library/react';
import { setTimeSlots, formatTimeSlotLabel, hearingTimeOptsWithZone } from 'app/hearings/utils';
import { axe } from 'jest-axe';

import REGIONAL_OFFICE_INFORMATION from '../../../../../constants/REGIONAL_OFFICE_INFORMATION';
import HEARING_TIME_OPTIONS from '../../../../../constants/HEARING_TIME_OPTIONS';

import moment from 'moment-timezone/moment-timezone';
import { drop } from 'lodash';

const emptyHearings = [];
const oneHearing = [{
  hearingTime: '10:15',
  externalId: '249a1443-0de4-44fd-bd93-58c30f14c703',
  issueCount: 1,
  poaName: 'AMERICAN POA EXAMPLE',
  docketName: 'L',
  docketNumber: '158-2284',

}];
const defaultRoCode = 'RO39';
const mockOnChange = jest.fn();
const defaultProps = {
  // Denver
  ro: defaultRoCode,
  roTimezone: REGIONAL_OFFICE_INFORMATION[defaultRoCode].timezone,
  scheduledHearingsList: emptyHearings,
  fetchScheduledHearings: jest.fn(),
  onChange: mockOnChange
};

const setup = (props = {}) => {
  const mergedProps = { ...defaultProps, ...props };

  const utils = render(<TimeSlot {...mergedProps} />);
  const container = utils.container;
  const timeSlots = setTimeSlots(
    mergedProps.scheduledHearingsList,
    mergedProps.ro,
    mergedProps.roTimezone,
  );
  const dropdownItems = hearingTimeOptsWithZone(
    HEARING_TIME_OPTIONS,
    mergedProps.roTimezone,
    mergedProps.roTimezone
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

const clickTimeslot = (time, timezone) => {
  fireEvent.click(screen.getByText(formatTimeSlotLabel(time, timezone)));
};

// This doesn't work yet
const clickDropwdownItem = (time, timezone) => {
  const dropdownContainer = document.getElementsByClassName('dropdown-optionalHearingTime0')[0];

  const select = dropdownContainer.querySelector('.cf-select');

  fireEvent.keyPress(select, { key: 'ArrowDown', code: '40' });
  fireEvent.keyPress(select, { key: 'ArrowDown', code: '40' });
  fireEvent.keyPress(select, { key: 'Enter', code: '13' });
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
    const eightThirtyAmEastern = moment.tz('8:30', 'HH:mm', 'America/New_York');
    const threeThirtyPmEastern = moment.tz('15:30', 'HH:mm', 'America/New_York');

    // This deals with Manila, which has a UTC offset of +8
    if (eightThirtyAmRoZone.isBefore(eightThirtyAmEastern)) {
      expect(timeSlots[0].time.isSame(eightThirtyAmEastern, 'hour')).toEqual(true);
    }
    // This is the more used case, for Eastern, Central, Mountain, and Pacific times
    if (eightThirtyAmRoZone.isSameOrAfter(eightThirtyAmEastern)) {
      expect(timeSlots[0].time.isSame(eightThirtyAmRoZone, 'hour')).toEqual(true);
    }
    // Last slot is at 3:30pm eastern
    expect(timeSlots[timeSlots.length - 1].time.isSame(threeThirtyPmEastern, 'hour')).toEqual(true);
  }
};
const firstDropdownItemCorrect = (ro, item) => {
  const eightFifteenRoTimeMoment = moment.tz('08:15', 'HH:mm', ro.timezone);
  const easternTimeString = eightFifteenRoTimeMoment.tz('America/New_York').format('h:mm');
  const roTimeString = eightFifteenRoTimeMoment.tz(ro.timezone).format('h:mm');

  expect(item.label).toContain(easternTimeString);
  expect(item.label).toContain(roTimeString);
};
const lastDropdownItemCorrect = (ro, item) => {
  const fourFortyFiveRoTimeMoment = moment.tz('16:45', 'HH:mm', ro.timezone);
  const easternTimeString = fourFortyFiveRoTimeMoment.tz('America/New_York').format('h:mm');
  const roTimeString = fourFortyFiveRoTimeMoment.tz(ro.timezone).format('h:mm');

  expect(item.label).toContain(easternTimeString);
  expect(item.label).toContain(roTimeString);
};

const firstLastAndCountOfDropdownItemsCorrect = (ro, dropdownItems) => {
  firstDropdownItemCorrect(ro, dropdownItems[0]);
  lastDropdownItemCorrect(ro, dropdownItems[dropdownItems.length - 1]);
  expect(dropdownItems.length).toEqual(35);
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

    it('should have 1 container for each time slot column and 1 button to change to custom time', () => {
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
      clickTimeslot('10:30', defaultProps.roTimezone);
      clickTimeslot('11:30', defaultProps.roTimezone);

      // Check that the correct elements are displayed
      expect(utils.getAllByRole('button')).toHaveLength(timeSlots.length + 1);
      expect(document.getElementsByClassName('time-slot-button-selected')).toHaveLength(1);
    });
  });

  describe('has correct behavior in multiple timezones', () => {
    const regionalOfficeCodes = [
      // Manilla, which is -earlier- than Eastern
      'RO58',
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
    const regionalOffices = regionalOfficeCodes.map((roCode) => {
      return { ro: roCode, timezone: REGIONAL_OFFICE_INFORMATION[roCode].timezone
      };
    });

    regionalOffices.forEach((ro) => {
      it('has correct slot times', () => {
        const { timeSlots, utils } = setup({ roTimezone: ro.timezone });

        // Sanity check, but also remove linting problems because expects are in sub-functions
        expect(timeSlots.length > 0).toEqual(true);
        firstAndLastSlotsAreCorrect(ro, timeSlots);

        // Toggle back and forth, check that they're still correct
        toggleBackAndForth(utils);
        firstAndLastSlotsAreCorrect(ro, timeSlots);
      });

      it('has correct custom dropdown options', () => {
        const { dropdownItems, utils } = setup({ roTimezone: ro.timezone });

        toggleToCustom(utils);
        // Check that the dropdown times are correct
        expect(dropdownItems.length > 0).toEqual(true);
        firstLastAndCountOfDropdownItemsCorrect(ro, dropdownItems);
        // Toggle back and forth, check that they're still correct
        toggleBackAndForth(utils);
        firstLastAndCountOfDropdownItemsCorrect(ro, dropdownItems);
      });

      it('has correct time values to submit to backend', () => {
        const { utils } = setup({ roTimezone: ro.timezone });

        const roTime = '12:30';

        // Click on the timeslot button for 12:30pm local
        clickTimeslot(roTime, ro.timezone);
        const easternTime = moment.tz(roTime, 'HH:mm', 'America/New_York').tz(ro.timezone).
          format('HH:mm');

        // Expect that we called onChange with 12:30pm ro timezone
        expect(mockOnChange).toHaveBeenLastCalledWith('scheduledTimeString', easternTime);

        // Switch to dropdown
        toggleToCustom(utils);

      });
      it('hearings have correct times', () => {
        const { timeSlots } = setup({ scheduledHearingsList: oneHearing, roTimezone: ro.timezone });

        // The timeSlots list actually contains a mix of hearings and slots, pull out the one hearing
        const hearingInSlotList = timeSlots.filter((item) => item.full === true);

        // Should only have one scheduled hearing
        expect(hearingInSlotList.length).toEqual(1);
        // Extract the time in Eastern
        const time = moment.tz(hearingInSlotList[0].hearingTime, 'HH:mm', 'America/New_York').format('h:mm A z');

        // Get the button, with that time
        const hearingButton = document.getElementsByClassName('time-slot-button-full');

        // Only one scheduled button should appear, it should have the correct time
        expect(hearingButton).toHaveLength(1);
        expect(hearingButton[0]).toHaveTextContent(time);

      });
    });
  });
})
;
