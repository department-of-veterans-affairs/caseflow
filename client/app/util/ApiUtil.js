import request from 'superagent';
import nocache from 'superagent-no-cache';
import ReactOnRails from 'react-on-rails';
import StringUtil from './StringUtil';

// TODO(jd): Fill in other HTTP methods as needed
const ApiUtil = {

  // Converts camelCase to snake_case
  convertToSnakeCase(data = {}) {
    if (typeof data !== 'object') {
      return data;
    }
    let result = {};

    for (let key in data) {
      if ({}.hasOwnProperty.call(data, key)) {
        let snakeKey = StringUtil.camelCaseToSnakeCase(key);

        // assign value to new object
        result[snakeKey] = this.convertToSnakeCase(data[key]);
      }
    }

    return result;
  },

  delete(url, options = {}) {
    return request.
      delete(url).
      set(this.headers(options.headers)).
      send(options.data).
      use(nocache);
  },

  get(url, options = {}) {
    return request.
      get(url).
      set(this.headers(options.headers)).
      query(options.query).
      use(nocache);
  },

  // Default headers needed to talk with rails server.
  // Including rail's authenticity token
  headers(options = {}) {
    let headers = Object.assign({},
      {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      ReactOnRails.authenticityHeaders(),
      options);


    return headers;
  },

  patch(url, options = {}) {
    return request.
      post(url).
      set(this.headers({ 'X-HTTP-METHOD-OVERRIDE': 'patch' })).
      send(options.data).
      use(nocache);
  },

  post(url, options = {}) {
    return request.
      post(url).
      set(this.headers(options.headers)).
      send(options.data).
      use(nocache);
  }
};

export default ApiUtil;
