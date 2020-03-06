import { expect } from 'chai';
import StringUtil from '../../../app/util/StringUtil';
import React from 'react';

describe('StringUtil', () => {
  context('.leftPad', () => {
    it('returns a padded string when provided empty string', () => {
      expect(StringUtil.leftPad('', 4, '0')).to.eq('0000');
    });

    it('returns an equal length string', () => {
      expect(StringUtil.leftPad('1234', 4, '0')).to.eq('1234');
    });

    it('truncates a string greater than padding length', () => {
      expect(StringUtil.leftPad('12345', 4, '0')).to.eq('2345');
    });

    it('returns a padded string when provided a short string', () => {
      expect(StringUtil.leftPad('12', 4, '0')).to.eq('0012');
    });
  });

  context('.titleCase', () => {
    it('handles snake_case', () => {
      expect(StringUtil.titleCase('snake_case')).to.eq('Snake Case');
    });

    it('handles camelCase', () => {
      expect(StringUtil.titleCase('camelCase')).to.eq('Camel Case');
    });

    it('handles single words', () => {
      expect(StringUtil.titleCase('title')).to.eq('Title');
    });
  });

  context('.nl2br', () => {
    it('converts \\n to <br> element', () => {
      const input = 'lorem ipsum \n dolor sit amet';
      const output = StringUtil.nl2br(input);

      expect(output.length).to.eq(2);

      const [el1, el2] = output;

      expect(el1.key).to.eq('0');
      expect(el1.props.children.length).to.eq(2);
      expect(el1.props.children[1].type).to.eq('br');

      expect(el2.key).to.eq('1');
      expect(el2.props.children.length).to.eq(2);
      expect(el2.props.children[1]).to.eq(null);
    });
  });
});
