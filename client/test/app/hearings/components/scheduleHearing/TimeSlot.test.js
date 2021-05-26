// libraries
import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import moment from 'moment-timezone/moment-timezone';
import { uniq } from 'lodash';
// caseflow
import { TimeSlot } from 'app/hearings/components/scheduleHearing/TimeSlot';
import { formatTimeSlotLabel, hearingTimeOptsWithZone, setTimeSlots, TIMEZONES_WITH_LUNCHBREAK } from 'app/hearings/utils';
// constants
import REGIONAL_OFFICE_INFORMATION from '../../../../../constants/REGIONAL_OFFICE_INFORMATION';
import HEARING_TIME_OPTIONS from '../../../../../constants/HEARING_TIME_OPTIONS';

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
  hearingDayDate: moment.tz().format('YYYY-MM-DD'),
  scheduledHearingsList: emptyHearings,
  numberOfSlots: '8',
  slotLengthMinutes: '60',
  fetchScheduledHearings: jest.fn(),
  onChange: mockOnChange
};

const setup = (props = {}) => {
  const mergedProps = { ...defaultProps, ...props };

  const utils = render(<TimeSlot {...mergedProps} />);
  const container = utils.container;
  const timeSlots = setTimeSlots(mergedProps);
  const dropdownItems = hearingTimeOptsWithZone(
    HEARING_TIME_OPTIONS,
    mergedProps.roTimezone,
    mergedProps.roTimezone
  );

  return { container, utils, timeSlots, dropdownItems };
};

const clickTimeslot = (time, timezone) => {
  fireEvent.click(screen.getByText(formatTimeSlotLabel(time, timezone)));
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
      // Central office ro, eastern
      'C',
      // New York, Eastern time
      'RO06',
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
      describe(`for ro (${ro.ro}) in zone (${ro.timezone})`, () => {
        [
        // I really want to put the comment inline, disable eslint locally to allow
        /* eslint-disable line-comment-position */
          '2021-04-21T12:30:00-07:00', // 9:30 eastern
          '2021-04-21T11:30:00-05:00', // 10:30 eastern
          '2021-04-21T14:30:00-06:00', // 12:30 eastern
          '2021-04-21T15:30:00-05:00', // 14:30 eastern, last slot
          '2023-06-21T12:30:00-07:00', // 9:30 eastern on a future day
        /* eslint-enable line-comment-position */
        ].forEach((beginsAtString) => {
          it(`shows all slots after beginsAt (${beginsAtString})`, () => {
            const beginsAt = moment(beginsAtString).tz('America/New_York');
            const numberOfSlots = 8;
            const slotLengthMinutes = 60;
            const { timeSlots } = setup({ roTimezone: ro.timezone, beginsAt, numberOfSlots, slotLengthMinutes });

            // Got the correct number of timeslots
            expect(timeSlots.length).toEqual(numberOfSlots);
            // First timeslot is the same as the beginsAt time
            expect(timeSlots[0].time.isSame(beginsAt)).toEqual(true);

            // Last slot time is correct
            const lastSlotTime = timeSlots[timeSlots.length - 1].time;
            const expectedLastSlotTime = beginsAt.clone().add((numberOfSlots - 1) * slotLengthMinutes, 'minute');

            expect((lastSlotTime).isSame(expectedLastSlotTime)).toEqual(true);

          });

          it(`correctly parses hearings and slots onto the date in beginsAt (${beginsAtString})`, () => {
            const beginsAt = moment(beginsAtString).tz('America/New_York');
            const hearingDayDate = beginsAt.tz(ro.timezone).format('YYYY-MM-DD');
            const { timeSlots } = setup({
              roTimezone: ro.timezone,
              beginsAt,
              hearingDayDate,
              scheduledHearingsList: oneHearing
            });

            const slotsAndHearingsOnBeginsAtDate = timeSlots.every((slotOrHearing) =>
              slotOrHearing.time.isSame(beginsAt, 'day'));

            expect(slotsAndHearingsOnBeginsAtDate).toBe(true);
          });
        });

        it('creates one slot', () => {
          const { timeSlots } = setup({ roTimezone: ro.timezone, numberOfSlots: 1 });

          expect(timeSlots.length).toEqual(1);
        });

        it('creates three 45 minute slots', () => {
          const numberOfSlots = 3;
          const slotLengthMinutes = 45;
          const beginsAt = moment('2021-04-21T08:30:00-04:00').tz('America/New_York');
          const { timeSlots } = setup({ roTimezone: ro.timezone, beginsAt, numberOfSlots, slotLengthMinutes });

          expect(timeSlots.length).toEqual(3);
          // Last slot time is correct
          const lastSlotTime = timeSlots[timeSlots.length - 1].time;
          const expectedLastSlotTime = beginsAt.clone().add((numberOfSlots - 1) * slotLengthMinutes, 'minute');

          expect(lastSlotTime.isSame(expectedLastSlotTime)).toBe(true);
        });

        it('slots have correct time values to submit to backend', () => {
          const { timeSlots, utils } = setup({ roTimezone: ro.timezone });

          const roTime = timeSlots[0].hearingTime;

          clickTimeslot(roTime, ro.timezone);
          const easternTime = moment.tz(roTime, 'HH:mm', 'America/New_York').tz(ro.timezone).
            format('HH:mm');

          // Expect that we called onChange with 12:30pm ro timezone
          expect(mockOnChange).toHaveBeenLastCalledWith('scheduledTimeString', easternTime);

        });

        it('moves following slots when there is a lunch break', () => {
          const beginsAt = moment('2021-04-21T08:30:00-04:00').tz('America/New_York');
          const lunchBreak = TIMEZONES_WITH_LUNCHBREAK.includes(ro.timezone);
          const { timeSlots } = setup({ lunchBreak, beginsAt, roTimezone: ro.timezone });

          expect(timeSlots[0].time.isSame(beginsAt)).toEqual(true);

          const [breakHour, breakMinute] = ['12', '30'];
          const lunchBreakMoment = beginsAt.clone().tz(ro.timezone).
            set({ hour: breakHour, minute: breakMinute });
          const firstSlotAfterLunchBreak = timeSlots.find((item) => item.time.isSameOrAfter(lunchBreakMoment));

          if (lunchBreak) {
            expect(firstSlotAfterLunchBreak.time.isSame(lunchBreakMoment.add(30, 'minutes'))).toEqual(true);
          }
        });

        it('hearings display correct times and hide slots appropriately', () => {
          const numberOfSlots = 8;
          const slotLengthMinutes = 60;
          const beginsAt = moment('2021-04-21T08:30:00-04:00').tz('America/New_York');
          const { timeSlots } = setup({
            scheduledHearingsList: oneHearing,
            roTimezone: ro.timezone,
            numberOfSlots,
            beginsAt,
            slotLengthMinutes
          });

          // The timeSlots list actually contains a mix of hearings and slots, pull out the one hearing
          const hearingInSlotList = timeSlots.filter((item) => item.full === true);

          // Should only have one scheduled hearing
          expect(hearingInSlotList.length).toEqual(1);

          // Extract the hearing time in Eastern
          const hearingTime = moment.tz(hearingInSlotList[0].hearingTime, 'HH:mm', 'America/New_York');

          // Get the time of the last slot
          const lastSlotTime = timeSlots[timeSlots.length - 1].time;

          // If the hearing is between two slots it hides two slots
          if (hearingTime.isBetween(beginsAt, lastSlotTime)) {
            expect(timeSlots.length).toEqual(hearingInSlotList.length + numberOfSlots - 2);
          }

          // If we have slots, check that they are hidden/shown correctly
          if (lastSlotTime) {
          // If the hearing is at the beginning or end of the day, which puts it within slotLengthMinutes
          // of only one slot, hide one slot
            const withinAnHourOfBeginsAt = Math.abs(beginsAt.diff(hearingTime, 'minutes')) < 60;
            const withinAnHourOflastSlotTime = Math.abs(lastSlotTime.diff(hearingTime, 'minutes')) < 60;

            if (withinAnHourOfBeginsAt && hearingTime.isBefore(beginsAt)) {
              expect(timeSlots.length).toEqual(hearingInSlotList.length + numberOfSlots - 1);
            }
            if (withinAnHourOflastSlotTime && hearingTime.isAfter(lastSlotTime)) {
              expect(timeSlots.length).toEqual(hearingInSlotList.length + numberOfSlots - 1);
            }
          }

          // If we have slots, check that the ids are unique
          if (lastSlotTime) {
            const uniqueKeys = uniq(timeSlots.map((slot) => slot.key));

            expect(timeSlots.length).toEqual(uniqueKeys.length);
          }

          // Get the button, with that time
          const hearingButton = document.getElementsByClassName('time-slot-button-full');

          // Only one scheduled button should appear, it should have the correct time
          const timeString = hearingTime.format('h:mm A z');

          expect(hearingButton).toHaveLength(1);
          expect(hearingButton[0]).toHaveTextContent(timeString);

        });
      });
    });
  });
})
;
