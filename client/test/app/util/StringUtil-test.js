import StringUtil from '../../../app/util/StringUtil';
import React from 'react';

describe('StringUtil', () => {
  describe('.leftPad', () => {
    it('returns a padded string when provided empty string', () => {
      expect(StringUtil.leftPad('', 4, '0')).toBe('0000');
    });

    it('returns an equal length string', () => {
      expect(StringUtil.leftPad('1234', 4, '0')).toBe('1234');
    });

    it('truncates a string greater than padding length', () => {
      expect(StringUtil.leftPad('12345', 4, '0')).toBe('2345');
    });

    it('returns a padded string when provided a short string', () => {
      expect(StringUtil.leftPad('12', 4, '0')).toBe('0012');
    });
  });

  describe('.titleCase', () => {
    it('handles snake_case', () => {
      expect(StringUtil.titleCase('snake_case')).toBe('Snake Case');
    });

    it('handles camelCase', () => {
      expect(StringUtil.titleCase('camelCase')).toBe('Camel Case');
    });

    it('handles single words', () => {
      expect(StringUtil.titleCase('title')).toBe('Title');
    });
  });

  describe('.nl2br', () => {
    it('converts \\n to <br> element', () => {
      const input = 'lorem ipsum \n dolor sit amet';
      const output = StringUtil.nl2br(input);

      expect(output.length).toBe(2);

      const [el1, el2] = output;

      expect(el1.key).toBe('0');
      expect(el1.props.children.length).toBe(2);
      expect(el1.props.children[1].type).toBe('br');

      expect(el2.key).toBe('1');
      expect(el2.props.children.length).toBe(2);
      expect(el2.props.children[1]).toBeNull();
    });
  });
});
