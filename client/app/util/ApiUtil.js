import request from 'superagent';
import nocache from 'superagent-no-cache';
import ReactOnRails from 'react-on-rails';
import StringUtil from './StringUtil';
import uuid from 'uuid';
import _ from 'lodash';
import { timeFunctionPromise } from '../util/PerfDebug';
import moment from 'moment';

export const STANDARD_API_TIMEOUT_MILLISECONDS = 60 * 1000;
export const RESPONSE_COMPLETE_LIMIT_MILLISECONDS = 5 * 60 * 1000;

const defaultTimeoutSettings = {
  response: STANDARD_API_TIMEOUT_MILLISECONDS,
  deadline: RESPONSE_COMPLETE_LIMIT_MILLISECONDS
};

const makeSendAnalyticsTimingFn = (httpVerbName) => (timeElapsedMs, url, options, endpointName) => {
  if (endpointName) {
    window.analyticsTiming({
      timingCategory: 'api-request',
      timingVar: endpointName,
      timingValue: timeElapsedMs,
      timingLabel: httpVerbName.toLowerCase()
    });
  }
};

const timeApiRequest = (httpFn, httpVerbName) => timeFunctionPromise(httpFn, makeSendAnalyticsTimingFn(httpVerbName));

// Default headers needed to talk with rails server.
// Including rails authenticity token
export const getHeadersObject = (options = {}) => {
  let headers = Object.assign({},
    {
      Accept: 'application/json',
      'Content-Type': 'application/json'
    },
    ReactOnRails.authenticityHeaders(),
    options);

  return headers;
};

export const postMetricLogs = (data) => {
  return request.
    post('/metrics/v2/logs').
    set(getHeadersObject()).
    send(data).
    use(nocache).
    on('error', (err) => console.error(`Metric not recorded\nUUID: ${uuid.v4()}.\n: ${err}`)).
    end();
};

// eslint-disable-next-line no-unused-vars
const errorHandling = (url, error, method, options = {}) => {
  const id = uuid.v4();
  const message = `UUID: ${id}.\nProblem with ${method} ${url}.\n${error}`;

  console.error(new Error(message));
  options.t1 = performance.now();
  options.end = moment().format();
  options.duration = options.t1 - options.t0;

  // Need to renable this check before going to master
  if (options?.metricsLogRestError) {
    const data = {
      metric: {
        uuid: id,
        name: `caseflow.client.rest.${method.toLowerCase()}.error`,
        message,
        type: 'error',
        product: 'caseflow',
        metric_attributes: JSON.stringify({
          method,
          url,
          error
        }),
        sent_to: 'javascript_console',
        start: options.start,
        end: options.end,
        duration: options.duration,
      }
    };

    postMetricLogs(data);
  }
};

const successHandling = (url, res, method, options = {}) => {
  const id = uuid.v4();
  const message = `UUID: ${id}.\nSuccess with ${method} ${url}.\n${res.status}`;

  // Need to renable this check before going to master
  options.t1 = performance.now();
  options.end = moment().format();
  options.duration = options.t1 - options.t0;

  if (options?.metricsLogRestSuccess) {
    const data = {
      metric: {
        uuid: id,
        name: `caseflow.client.rest.${method.toLowerCase()}.info`,
        message,
        type: 'info',
        product: 'caseflow',
        metric_attributes: JSON.stringify({
          method,
          url
        }),
        sent_to: 'javascript_console',
        sent_to_info: JSON.stringify({
          metric_group: 'Rest call',
          metric_name: 'Javascript request',
          metric_value: options.duration,
          app_name: 'JS reader',
          attrs: {
            service: 'rest service',
            endpoint: url,
            uuid: id
          }
        }),

        start: options.start,
        end: options.end,
        duration: options.duration,
      }
    };

    postMetricLogs(data);
  }
};

const httpMethods = {
  delete(url, options = {}) {
    options.t0 = performance.now();
    options.start = moment().format();

    return request.
      delete(url).
      set(getHeadersObject(options.headers)).
      send(options.data).
      use(nocache).
      on('error', (err) => errorHandling(url, err, 'DELETE', options)).
      then((res) => {
        successHandling(url, res, 'DELETE', options);

        return res;
      });
  },

  get(url, options = {}) {
    const timeoutSettings = Object.assign({}, defaultTimeoutSettings, _.get(options, 'timeout', {}));

    options.t0 = performance.now();
    options.start = moment().format();

    let promise = request.
      get(url).
      set(getHeadersObject(options.headers)).
      query(options.query).
      timeout(timeoutSettings).
      on('error', (err) => errorHandling(url, err, 'GET', options));

    if (options.responseType) {
      promise.responseType(options.responseType);
    }

    if (options.withCredentials) {
      promise.withCredentials();
    }

    if (options.cache) {
      return promise.
      then((res) => {
        successHandling(url, res, 'GET', options);
        return res;
      });
    }

    return promise.
      use(nocache).
      then((res) => {
        successHandling(url, res, 'GET', options);
        return res;
      });
  },

  patch(url, options = {}) {
    options.t0 = performance.now();
    options.start = moment().format();

    return request.
      post(url).
      set(getHeadersObject({ 'X-HTTP-METHOD-OVERRIDE': 'patch' })).
      send(options.data).
      use(nocache).
      on('error', (err) => errorHandling(url, err, 'PATCH', options)).
      then((res) => {
        successHandling(url, res, 'PATCH', options);

        return res;
      });
  },

  post(url, options = {}) {
    options.t0 = performance.now();
    options.start = moment().format();

    return request.
      post(url).
      set(getHeadersObject(options.headers)).
      send(options.data).
      use(nocache).
      on('error', (err) => errorHandling(url, err, 'POST', options)).
      then((res) => {
        successHandling(url, res, 'POST', options);

        return res;
      });
  },

  put(url, options = {}) {
    options.t0 = performance.now();
    options.start = moment().format();

    return request.
      put(url).
      set(getHeadersObject(options.headers)).
      send(options.data).
      use(nocache).
      on('error', (err) => errorHandling(url, err, 'PUT', options)).
      then((res) => {
        successHandling(url, res, 'PUT', options);

        return res;
      });
  }

};

// TODO(jd): Fill in other HTTP methods as needed
const ApiUtil = {

  // Converts camelCase to snake_case
  convertToSnakeCase(data) {
    if (!_.isObject(data)) {
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

  convertToCamelCase(data) {
    if (!_.isObject(data)) {
      return data;
    }
    let result = {};

    for (let key in data) {
      if ({}.hasOwnProperty.call(data, key)) {
        let camelCase = StringUtil.snakeCaseToCamelCase(key);

        // assign value to new object
        result[camelCase] = this.convertToCamelCase(data[key]);
      }
    }

    return result;
  },

  ..._.mapValues(httpMethods, timeApiRequest)
};

export default ApiUtil;
