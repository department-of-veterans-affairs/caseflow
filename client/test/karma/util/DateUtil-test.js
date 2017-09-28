import { expect } from 'chai';
import { formatDate, formatDateStr, doDatesMatch, formatArrayOfDateStrings } from '../../../app/util/DateUtil';

describe('DateUtil', () => {
  context('.formatDate', () => {
    it('returns a date formatted mm/dd/yyyy', () => {
      expect(formatDate('1/2/2017')).to.eq('01/02/2017');
    });
  });

  context('.formatArrayOfDateStrings', () => {
    it('returns a comma separated string of dates formatted mm/dd/yyyy', () => {
      expect(formatArrayOfDateStrings(['1/2/2017', '1/3/2017'])).to.eq('01/02/2017, 01/03/2017');
    });
  });

  context('.formatDateStr', () => {
    it('returns a date formatted mm/dd/yyyy', () => {
      expect(formatDateStr('2017-04-24')).to.eq('04/24/2017');
    });
  });

  /* eslint-disable no-unused-expressions */
  context('.doDatesMatch', () => {
    it('checks to see a string query is part of a date', () => {
      expect(doDatesMatch('2022-06-31', '06/31/2022')).to.be.true;
      expect(doDatesMatch('2017-06-28', '06-28-2017')).to.be.true;
      expect(doDatesMatch('2017-06-12', '6/12/20')).to.be.true;
      expect(doDatesMatch('2017-06-12', '6/')).to.be.true;
      expect(doDatesMatch('2022-02-12', '02-')).to.be.true;
      expect(doDatesMatch('2022-02-01', '2-1-2022')).to.be.true;
      expect(doDatesMatch('2022-02-12', '-02-12')).to.be.false;
      expect(doDatesMatch('2022-02-12', 'a2-12-22')).to.be.false;
      expect(doDatesMatch('2022-02-12', '02-2022-02')).to.be.false;
      expect(doDatesMatch('2022-02-12', '2017 ')).to.be.false;
      expect(doDatesMatch('2022-02-12', '/2022')).to.be.true;
    });
  });
  /* eslint-disable no-unused-expressions */
});
