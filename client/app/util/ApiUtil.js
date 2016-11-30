import request from 'superagent';
import nocache from 'superagent-no-cache';
import ReactOnRails from 'react-on-rails';

// TODO(jd): Fill in other HTTP methods as needed
const ApiUtil = {
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

  post(url, options = {}) {
    return request.
      post(url).
      set(this.headers(options.headers)).
      send(options.data).
      use(nocache);
  },

  patch(url, options = {}) {
    return request.
      post(url).
      set(this.headers({ 'X-HTTP-METHOD-OVERRIDE': 'patch' })).
      send(options.data).
      use(nocache);
  },

  // Converts snakeCase to camel_case
  convertToSnakeCase(data = {}) {
    let result = {};

    for (let key in data) {
      if (data.hasOwnProperty(key)) {
        // convert key from camelCase to snake_case
        let snakeKey = key.replace(/([A-Z])/g, function($1){return "_"+$1.toLowerCase();});

        // assign value to new object
        result[snakeKey] = data[key];
      }
    }
    return result;
  }
};

export default ApiUtil;
