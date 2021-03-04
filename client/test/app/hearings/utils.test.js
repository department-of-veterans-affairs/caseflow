import { setTimeSlots } from 'app/hearings/utils';
import { uniq } from 'lodash';

// Create a pair of scheduled and next to ensure the next is filtered
const timeSlot1 = {
  scheduled: '08:45',
  hiddenSlot: '09:30',
};

// Create a pair of scheduled and previous to ensure the previous still displays
const timeSlot2 = {
  shownSlot: '10:30',
  scheduled: '10:45',
};

// Store a constant for the last available time to test against
const LAST_AVAILABLE_TIME = '15:30';

// Create a constant to test against a time that is unavailable
const UNAVAILABLE_TIME = '16:30';

// Create a variable to track the scheduled time after the 3:30 cutoff
const scheduledHearingAfterTime = '16:45';

const emptyHearings = [];
const scheduledHearingNext = [
  {
    hearingTime: timeSlot1.scheduled
  }
];

const scheduledHearingPrevious = [
  {
    hearingTime: timeSlot2.scheduled
  }
];

const scheduledHearingAfter = [
  {
    hearingTime: scheduledHearingAfterTime
  }
];

// Set the slot count equal to the number of hours between 8am and 3pm on 30 minute increments
const AVAILABLE_SLOT_COUNT = 8;

describe('hearing utils', () => {
  describe('setTimeSlots() function', () => {
    // beforeEach(() => {
    // });

    test('Displays every hour on the half hour when no hearings have been scheduled up to 3:30pm EST', () => {

      // Call the function and assign to the results object for inspection
      const result = setTimeSlots(emptyHearings);

      // Expect to return the same number of slots as we started with
      expect(result).toHaveLength(AVAILABLE_SLOT_COUNT);
      expect(result[result.length - 1].hearingTime).toEqual(LAST_AVAILABLE_TIME);
    });

    test('Skips the next available slot if a hearing is scheduled within an hour', () => {
      // Call the function and assign to the results object for inspection
      const result = setTimeSlots(scheduledHearingNext);

      // Expect the slot count to be the same as the number available when we have filtered 1 out
      expect(result).toHaveLength(AVAILABLE_SLOT_COUNT);

      // Expect the results to contain the scheduled time slot but not the next 30 minute increment
      expect(result).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            full: true,
            hearingTime: timeSlot1.scheduled
          }),
          expect.not.objectContaining({
            hearingTime: timeSlot1.hiddenSlot
          })
        ])
      );

      // Ensure the last available is still 3:30
      expect(result[result.length - 1].hearingTime).toEqual(LAST_AVAILABLE_TIME);
    });

    test('Does not skip the previous slot if a hearing is scheduled within an hour', () => {
      // Call the function and assign to the results object for inspection
      const result = setTimeSlots(scheduledHearingPrevious);

      // Expect the slot count to be the same as the number available when we have filtered 1 out
      expect(result).toHaveLength(AVAILABLE_SLOT_COUNT);

      // Expect the results to contain the scheduled time slot but not the next 30 minute increment
      expect(result).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            full: true,
            hearingTime: timeSlot2.scheduled
          }),
          expect.objectContaining({
            full: false,
            hearingTime: timeSlot2.shownSlot
          })
        ])
      );

      // Ensure the last available is still 3:30
      expect(result[result.length - 1].hearingTime).toEqual(LAST_AVAILABLE_TIME);
    });

    test('Displays scheduled hearing times after 3:30, but not any available time slots', () => {
      // Call the function and assign to the results object for inspection
      const result = setTimeSlots(scheduledHearingAfter);

      // Expect the slot count to be the same as the number available plus the hearings scheduled after 3:30
      expect(result).toHaveLength(AVAILABLE_SLOT_COUNT + scheduledHearingAfter.length);

      // Expect the results to contain the scheduled time slot but not a slot after 3:30
      expect(result).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            full: true,
            hearingTime: scheduledHearingAfterTime
          }),
          expect.not.objectContaining({
            full: false,
            hearingTime: UNAVAILABLE_TIME
          })
        ])
      );

      // Ensure the last available is not 3:30 but the last scheduled
      expect(result[result.length - 1].hearingTime).toEqual(scheduledHearingAfterTime);
    });

    test('With a scheduled hearing at 10:30, displays a slot for 09:30 and 11:30', () => {
      const result = setTimeSlots([{ hearingTime: '10:30' }]);

      expect(result).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            full: false,
            hearingTime: '09:30',
          }),
          expect.objectContaining({
            full: true,
            hearingTime: '10:30',
          }),
          expect.objectContaining({
            full: false,
            hearingTime: '11:30',
          })
        ])
      );

    });

    test('Key is unique for all slots', () => {
      const result = setTimeSlots([{ hearingTime: '10:30' }]);
      const dedupResult = uniq(result.map((slot) => slot.key));

      expect(result.length).toEqual(dedupResult.length);
    });
  });
});
