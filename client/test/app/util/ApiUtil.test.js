import ApiUtil, { getHeadersObject } from 'app/util/ApiUtil';
import request from 'superagent';
import nocache from 'superagent-no-cache';

jest.mock('superagent-no-cache');

jest.mock('superagent', () => ({
  post: jest.fn().mockReturnThis(),
  get: jest.fn().mockReturnThis(),
  send: jest.fn().mockReturnThis(),
  query: jest.fn().mockReturnThis(),
  field: jest.fn().mockReturnThis(),
  type: jest.fn().mockReturnThis(),
  set: jest.fn().mockReturnThis(),
  accept: jest.fn().mockReturnThis(),
  timeout: jest.fn().mockReturnThis(),
  use: jest.fn().mockReturnThis(),
  on: jest.fn().mockReturnThis(),
}));

const defaultHeaders = {
  'X-CSRF-Token': null,
  'X-Requested-With': 'XMLHttpRequest',
  Accept: 'application/json',
  'Content-Type': 'application/json'
};

describe('ApiUtil', () => {
  describe('getHeadersObject', () => {
    test('returns default headers', () => {
      const headers = getHeadersObject();

      expect(headers.Accept).toBe('application/json');
      expect(headers['Content-Type']).toBe('application/json');
      expect(headers).toHaveProperty('X-CSRF-Token');
    });
  });

  describe('.patch', () => {
    test('returns modified Request object', () => {
      // Setup the test
      const options = { data: { sample: 'data' } };

      // Run the test
      const req = ApiUtil.patch('/foo', options);

      // Expectations
      expect(request.post).toHaveBeenCalledWith('/foo');
      expect(request.set).toHaveBeenCalledWith({
        ...defaultHeaders,
        'X-HTTP-METHOD-OVERRIDE': 'patch'
      });
      expect(request.send).toHaveBeenCalledWith(options.data);
      expect(request.use).toHaveBeenCalledWith(nocache);
      expect(req).toMatchObject(request);
    });
  });

  describe('.post', () => {
    test('returns modified Request object', () => {
      // Setup the test
      const options = { data: { sample: 'data' } };

      // Run the test
      const req = ApiUtil.post('/bar', options);

      // Expectations
      expect(request.post).toHaveBeenCalledWith('/bar');
      expect(request.set).toHaveBeenCalledWith(defaultHeaders);
      expect(request.send).toHaveBeenCalledWith(options.data);
      expect(request.use).toHaveBeenCalledWith(nocache);
      expect(req).toMatchObject(request);
    });

    test('attaches custom headers when provided', () => {
      // Setup the test
      const options = { headers: { sample: 'header' } };

      // Run the test
      const req = ApiUtil.post('/bar', options);

      // Expectations
      expect(request.post).toHaveBeenCalledWith('/bar');
      expect(request.set).toHaveBeenCalledWith({
        ...defaultHeaders,
        ...options.headers
      });
      expect(request.send).toHaveBeenCalledWith(undefined);
      expect(request.use).toHaveBeenCalledWith(nocache);
      expect(req).toMatchObject(request);
    });
  });

  describe('.convertToSnakeCase', () => {
    let obj;

    beforeEach(() => {
      obj = {
        camelCaseKey: 'val',
        nestedKey: { secondaryKey: 'val3' },
        secondKey: 'val2'
      };
    });

    test('converts object keys', () => {
      let result = ApiUtil.convertToSnakeCase(obj);
      let length = 3;

      expect(Object.keys(result).length).toBe(length);
      expect(result.camel_case_key).toBe('val');
      expect(result.second_key).toBe('val2');
      expect(result.nested_key.secondary_key).toBe('val3');
    });
  });

  describe('.get', () => {
    test('returns modified Request object', () => {
      // Setup the test
      const options = { query: { bar: 'baz' } };

      // Run the test
      const req = ApiUtil.get('/foo', options);

      // Expectations
      expect(request.get).toHaveBeenCalledWith('/foo');
      expect(request.set).toHaveBeenCalledWith(defaultHeaders);
      expect(request.query).toHaveBeenCalledWith(options.query);
      expect(request.use).toHaveBeenCalledWith(nocache);
      expect(req).toMatchObject(request);
    });
  });
});
