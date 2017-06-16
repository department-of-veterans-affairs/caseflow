import { expect } from 'chai';
import ApiUtil from '../../../app/util/ApiUtil';

describe('ApiUtil', () => {
  context('.convertToSnakeCase', () => {

    /* eslint-disable no-undefined */
    const camelCaseObject = {
      emptyStringField: '',
      falseField: false,
      undefinedField: undefined,
      vacolsId: null,
      vacolsName: {
        firstName: 'Jane',
        lastName: 'Smith'
      }
    };

    const snakeCaseObject = {
      empty_string_field: '',
      false_field: false,
      undefined_field: undefined,
      vacols_id: null,
      vacols_name: {
        first_name: 'Jane',
        last_name: 'Smith'
      }
    };
    /* eslint-enable no-undefined */

    it('returns a correctly formatted object', () => {
      expect(ApiUtil.convertToSnakeCase(camelCaseObject)).to.deep.equal(snakeCaseObject);
    });

    it('returns an empty object', () => {
      expect(ApiUtil.convertToSnakeCase({})).to.deep.equal({});
    });

    it('returns a null object', () => {
      expect(ApiUtil.convertToSnakeCase(null)).to.deep.equal(null);
    });
  });
});
