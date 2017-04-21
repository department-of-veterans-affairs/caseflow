import { expect } from 'chai';
import { formatDate } from '../../../app/util/DateUtil';

describe('DateUtil', () => {
  context('.formatDate', () => {
    it('returns a hyphened date formatted mm/dd/yyyy', () => {
      expect(formatDate('1-2-2017')).to.eq('01/02/2017');
    });

    it('returns a slashed date formatted mm/dd/yyyy', () => {
      expect(formatDate('1/2/2017')).to.eq('01/02/2017');
    });
  });
});
