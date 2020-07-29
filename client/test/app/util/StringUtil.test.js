import StringUtil from 'app/util/StringUtil';
import { v4 as uuidv4 } from 'uuid';

describe('StringUtil', () => {
  describe('parseLinks', () => {
    const uuid = uuidv4();
    const links = [
      `https://appeals.cf.ds.va.gov/reader/appeal/${uuid}/documents/42416990`,
    ];

    test('within other text, surrounded by spaces', () => {
      const input = `foo ${links[0]} bar`;
      const output = StringUtil.parseLinks(input);
      const expected = `foo <a href="${links[0]}">${links[0]}</a> bar`;

      expect(output).toBe(expected);
    });

    test('within other text, surrounded by new lines', () => {
      const input = `foo\n${links[0]}\nbar`;
      const output = StringUtil.parseLinks(input);
      const expected = `foo\n<a href="${links[0]}">${links[0]}</a>\nbar`;

      expect(output).toBe(expected);
    });
  });
});
