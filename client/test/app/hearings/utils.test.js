import { setTimeSlots } from 'app/hearings/utils';
import { uniq } from 'lodash';

// Store a constant for the last available time to test against
const LAST_AVAILABLE_TIME = '15:30';
// Create a constant to test against a time that is unavailable
const UNAVAILABLE_TIME = '16:30';

// Set the slot count equal to the number of hours between 8am and 3pm on 30 minute increments
const AVAILABLE_SLOT_COUNT = 8;

describe('hearing utils', () => {
  describe('setTimeSlots() function', () => {

    test('Displays every hour on the half hour when no hearings have been scheduled up to 3:30pm EST', () => {

      // Empty array represents no hearings scheduled
      const result = setTimeSlots([]);

      // 7 empty slots and 1 full slot == 8
      expect(result).toHaveLength(8);

      expect(result[result.length - 1].hearingTime).toEqual(LAST_AVAILABLE_TIME);
    });

    test('Skips the next available slot if a hearing is scheduled within an hour', () => {
      // One hearing with a time of '08:45'
      const result = setTimeSlots([
        {
          // Should hide the 8:30 slot
          hearingTime: '08:45'
          // Should hide the 9:30 slot
          // Should show the 10:30 slot
        }
      ]);

      // Scheduled hearings: [08:45]
      // possible_slots: [8:30, 9:30, 10:30, 11:30, 12:30, 1:30, 2:30, 3:30]
      // hidden_slots: [8:30, 9:30]
      // possible_slots - hidden_slots = empty_slots
      // empty_slots: [10:30, 11:30, 12:30, 1:30, 2:30, 3:30]
      // result_length = empty_slots.length + scheduled_hearings.length
      expect(result).toHaveLength(7);

      expect(result).toEqual(
        expect.arrayContaining([
          expect.not.objectContaining({
            hearingTime: '08:30'
          }),
          expect.objectContaining({
            full: true,
            hearingTime: '08:45'
          }),
          expect.not.objectContaining({
            hearingTime: '09:30'
          }),
          expect.objectContaining({
            hearingTime: '10:30'
          })
        ])
      );

      // Ensure the last available is still 3:30
      expect(result[result.length - 1].hearingTime).toEqual(LAST_AVAILABLE_TIME);
    });

    test('Displays scheduled hearing times after 3:30, but not any available time slots', () => {
      // Call the function and assign to the results object for inspection
      const result = setTimeSlots([
        {
          hearingTime: '16:45'
        }
      ]);

      // Expect the slot count to be the same as the number available plus the one hearing scheduled after 3:30
      expect(result).toHaveLength(AVAILABLE_SLOT_COUNT + 1);

      // Expect the results to contain the scheduled time slot but not a slot after 3:30
      expect(result).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            full: true,
            hearingTime: '16:45'
          }),
          expect.not.objectContaining({
            full: false,
            hearingTime: UNAVAILABLE_TIME
          })
        ])
      );

      // Ensure the last available is not 3:30 but the last scheduled
      expect(result[result.length - 1].hearingTime).toEqual('16:45');
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

    test('With a scheduled hearing at 09:30, dont display slot for 09:30', () => {
      const result = setTimeSlots([{ hearingTime: '09:30' }]);

      const nineThirtySlotExists = result.some((slot) =>
        slot.hearingTime === '09:30' && slot.full === false
      );

      expect(nineThirtySlotExists).toEqual(false);
    });

    test('Key is unique for all slots', () => {
      const result = setTimeSlots([{ hearingTime: '10:30' }]);
      const dedupResult = uniq(result.map((slot) => slot.key));

      expect(result.length).toEqual(dedupResult.length);
    });
  });
});
