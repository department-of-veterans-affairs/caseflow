import { expect } from 'chai';
import ApiUtil from '../../../app/util/ApiUtil';

describe('ApiUtil', () => {
  context('.convertToSnakeCase', () => {

    let camelCaseObject = {
      vacolsId: null,
      vacolsName: {
        firstName: 'Jane',
        lastName: 'Smith'
      }
    };

    let snakeCaseObject = {
      vacols_id: null,
      vacols_name: {
        first_name: 'Jane',
        last_name: 'Smith'
      }
    };

    it('returns a correctly formatted object', () => {
      expect(ApiUtil.convertToSnakeCase(camelCaseObject)).to.eql(snakeCaseObject);
    });

    it('returns an empty object', () => {
      expect(ApiUtil.convertToSnakeCase({})).to.eql({});
    });

    it('returns a null object', () => {
      expect(ApiUtil.convertToSnakeCase(null)).to.eql(null);
    });
  });
});
