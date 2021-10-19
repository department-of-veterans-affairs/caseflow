import { formatDate, formatDateStr, doDatesMatch, formatArrayOfDateStrings } from '../../../app/util/DateUtil';

describe('DateUtil', () => {
  describe('.formatDate', () => {
    it('returns a date formatted mm/dd/yyyy', () => {
      let date = new Date('1/2/2017');

      expect(formatDate(date.toISOString())).toBe('01/02/2017');
    });
    it('must be a ISO8601 string', () => {
      let badISOString = function() {
        formatDate('1/2/2017');
      };

      expect(badISOString).toThrowError(Error);
    });
  });

  describe('.formatArrayOfDateStrings', () => {
    it('returns a comma separated string of dates formatted mm/dd/yyyy', () => {
      expect(formatArrayOfDateStrings(['1/2/2017', '1/3/2017'])).toBe('01/02/2017, 01/03/2017');
    });
  });

  describe('.formatDateStr', () => {
    it('returns a date formatted mm/dd/yyyy', () => {
      expect(formatDateStr('2017-04-24')).toBe('04/24/2017');
      expect(formatDateStr('1/2/2017')).toBe('01/02/2017');
    });
  });

  /* eslint-disable no-unused-expressions */
  describe('.doDatesMatch', () => {
    it('checks to see a string query is part of a date', () => {
      expect(doDatesMatch('2022-06-31', '06/31/2022')).toBe(true);
      expect(doDatesMatch('2017-06-28', '06-28-2017')).toBe(true);
      expect(doDatesMatch('2017-06-12', '6/12/20')).toBe(true);
      expect(doDatesMatch('2017-06-12', '6/')).toBe(true);
      expect(doDatesMatch('2022-02-12', '02-')).toBe(true);
      expect(doDatesMatch('2022-02-01', '2-1-2022')).toBe(true);
      expect(doDatesMatch('2022-02-12', '-02-12')).toBe(false);
      expect(doDatesMatch('2022-02-12', 'a2-12-22')).toBe(false);
      expect(doDatesMatch('2022-02-12', '02-2022-02')).toBe(false);
      expect(doDatesMatch('2022-02-12', '2017 ')).toBe(false);
      expect(doDatesMatch('2022-02-12', '/2022')).toBe(true);
    });
  });
  /* eslint-disable no-unused-expressions */
});
