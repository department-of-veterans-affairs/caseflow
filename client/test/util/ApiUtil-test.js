import { expect } from 'chai';
import ApiUtil from '../../app/util/ApiUtil';

describe('ApiUtil', () => {
  context('.headers', () => {
    it('returns default headers', () => {
      let headers = ApiUtil.headers();

      expect(headers.Accept).to.eq('application/json');
      expect(headers['Content-Type']).to.eq('application/json');
      expect(Object.keys(headers)).to.include('X-CSRF-Token');
    });
  });

  context('.patch', () => {
    it('returns Request object', () => {
      let req = ApiUtil.patch('/foo');

      expect(req.url).to.eq('/foo');
      expect(req.header['X-HTTP-METHOD-OVERRIDE']).to.eq('patch');
      expect(req.header['Cache-Control']).to.include('no-cache');
    });
  });

  context('.post', () => {
    it('returns Request object', () => {
      let req = ApiUtil.post('/bar');

      expect(req.url).to.eq('/bar');
      expect(req.header['Cache-Control']).to.include('no-cache');
    });
  });

  context('.convertToSnakeCase', () => {
    let obj;

    beforeEach(() => {
      obj = {
        camelCaseKey: 'val',
        secondKey: 'val2'
      };
    });

    it('converts object keys', () => {
      let result = ApiUtil.convertToSnakeCase(obj);
      let length = 2;

      expect(Object.keys(result).length).to.eq(length);
      expect(result.camel_case_key).to.eq('val');
      expect(result.second_key).to.eq('val2');
    });
  });

  context('.get', () => {
    let req = ApiUtil.get('/foo', { query: { bar: 'baz' } });

    expect(req.url).to.eq('/foo');
    expect(req.qs.bar).to.eq('baz');
    expect(req.header['Cache-Control']).to.include('no-cache')
  });
});
