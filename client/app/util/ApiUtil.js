import request from 'superagent';
import nocache from 'superagent-no-cache';
import ReactOnRails from 'react-on-rails';

// TODO(jd): Fill in other HTTP methods as needed
const ApiUtil = {

  // Converts snake_case to camelCase
  convertToSnakeCase(data = {}) {
    let result = {};

    for (let key in data) {
      if ({}.hasOwnProperty.call(data, key)) {
        // convert key from camelCase to snake_case
        let snakeKey = key.replace(/([A-Z])/g, ($1) => `_${$1.toLowerCase()}`);

        // assign value to new object
        result[snakeKey] = data[key];
      }
    }

    return result;
  },

  // Converts regular language to camelCase
  convertToCamelCase(phrase = '') {
    return phrase.toLowerCase().replace(/[^a-zA-Z ]/g, "").replace(/(?:^\w|[A-Z]|\b\w|\s+)/g, function(match, index) {
      if (+match === 0) return ""; // or if (/\s+/.test(match)) for white spaces
      return index == 0 ? match.toLowerCase() : match.toUpperCase();
    });
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
