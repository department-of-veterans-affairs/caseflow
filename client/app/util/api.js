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

  patch(url, options = {}) {
    return request
      .post(url)
      .set(this.headers({ 'X-HTTP-METHOD-OVERRIDE': 'patch' }))
      .send(options.data)
      .use(nocache);
  }
};

export default ApiUtil;
