import { expect } from 'chai';
import { leftPad } from '../../app/util/StringUtil';

describe('StringUtil', () => {
  context('.leftPad', () => {
    it('returns a padded string when provided empty string', () => {
      expect(leftPad('', 4, '0')).to.eq('0000');
    });

    it('returns an equal length string', () => {
      expect(leftPad('1234', 4, '0')).to.eq('1234');
    });

    it('truncates a string greater than padding length', () => {
      expect(leftPad('12345', 4, '0')).to.eq('2345');
    });

    it('returns a padded string when provided a short string', () => {
      expect(leftPad('12', 4, '0')).to.eq('0012');
    });
  });
});
