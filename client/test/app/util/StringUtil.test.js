import StringUtil from 'app/util/StringUtil';
import { v4 as uuidv4 } from 'uuid';

describe('StringUtil', () => {
  describe('parseLinks', () => {
    const uuid = uuidv4();
    const links = [
      `https://appeals.cf.ds.va.gov/reader/appeal/${uuid}/documents/42416990`,
      `https://appeals.cf.ds.va.gov/reader/appeal/${uuid}/documents/42416990?foo=bar`,
    ];

    test('within other text, surrounded by spaces', () => {
      for (const link of links) {
        const input = `foo ${link} bar`;
        const output = StringUtil.parseLinks(input);

        const expected = `foo <a target="_blank" href="${link}">${link}</a> bar`;

        expect(output).toBe(expected);
      }
    });

    test('within other text, surrounded by new lines', () => {
      for (const link of links) {
        const input = `foo\n${link}\nbar`;
        const output = StringUtil.parseLinks(input);
        const expected = `foo\n<a target="_blank" href="${link}">${link}</a>\nbar`;

        expect(output).toBe(expected);
      }
    });

    test('allows a custom target', () => {
      const options = { target: '' };

      for (const link of links) {
        const input = `foo ${link} bar`;
        const output = StringUtil.parseLinks(input, options);
        const expected = `foo <a href="${link}">${link}</a> bar`;

        expect(output).toBe(expected);
      }
    });
  });
});
