import { expect } from 'chai';
import { formatDate, formatDateStr } from '../../../app/util/DateUtil';

describe('DateUtil', () => {
  context('.formatDate', () => {
    it('returns a date formatted mm/dd/yyyy', () => {
      expect(formatDate('1/2/2017')).to.eq('01/02/2017');
    });
  });

  context('.formatDate', () => {
    it('returns a date formatted mm/dd/yyyy', () => {
      expect(formatDateStr('2017-04-24')).to.eq('04/24/2017');
    });
  });
});
