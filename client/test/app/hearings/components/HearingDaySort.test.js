import {sortHearings} from '../../../../app/hearings/utils'

const hearingsMultipleTimezones = [
  // 2:00pm  eastern
  { scheduledFor: '2021-01-25T11:00:00.000-08:00', ordered: 2 }, 
  // 2:15pm  eastern
  { scheduledFor: '2021-01-25T11:15:00.000-08:00', ordered: 3 }, 
  // 11:15am eastern
  { scheduledFor: '2021-01-25T11:15:00.000-05:00', ordered: 0 }, 
  // 12 noon eastern
  { scheduledFor: '2021-01-25T12:00:00.000-05:00', ordered: 1 }  
];
const hearingsOneTimezone = [
  // 2:00pm  eastern
  { scheduledFor: '2021-01-25T14:00:00.000-05:00', ordered: 2 }, 
  // 2:15pm  eastern
  { scheduledFor: '2021-01-25T14:15:00.000-05:00', ordered: 3 }, 
  // 11:15am eastern
  { scheduledFor: '2021-01-25T11:15:00.000-05:00', ordered: 0 }, 
  { scheduledFor: '2021-01-25T12:00:00.000-05:00', ordered: 1 }, 
];

describe('HearingDay hearing sort order', () => {
  test('Sorts correctly when scheduledFor has one timezone on all hearings', () => {
    const sorted = sortHearings(hearingsOneTimezone);

    sorted.map((hearing, index) => {
      expect(hearing.ordered).toEqual(index);
    });
  });

  test('Sorts correctly when scheduledFor has multiple timezones', () => {
    const sorted = sortHearings(hearingsMultipleTimezones);

    sorted.map((hearing, index) => {
      expect(hearing.ordered).toEqual(index);
    });
  });
});
