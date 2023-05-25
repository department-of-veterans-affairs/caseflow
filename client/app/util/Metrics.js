import ApiUtil from './ApiUtil';
import _ from 'lodash';
import moment from 'moment';
import uuid from 'uuid';

const INTERVAL_TO_SEND_METRICS_MS = moment.duration(60, 'seconds');

let histograms = [];

const sendHistogram = () => {
  if (histograms.length === 0) {
    return;
  }

  ApiUtil.post('/metrics/v1/histogram', { data: { histograms } }).
    catch((error) => {
      console.error(error);
    });
  histograms = [];
};

const initialize = _.once(() => {
  // Only record values for a sample of our users.
  if (_.random(2) === 0) {
    // Add jitter to requests
    setInterval(sendHistogram, INTERVAL_TO_SEND_METRICS_MS + _.random(moment.duration(5, 'seconds')));
  }
});

export const collectHistogram = (data) => {
  initialize();

  histograms.push(ApiUtil.convertToSnakeCase(data));
};

export const recordMetrics = (data, uniqueId, isError = false) => {
  let id = uniqueId;

  // If a uuid wasn't provided assume that metric also wasn't sent to javascript console and send with UUID to console
  if (!uniqueId) {
    id = uuid.v4();
    if (isError) {
      console.error(`${id}\n${data}`);
    } else {
      // eslint-disable-next-line no-console
      console.log(`${id}\n${data}`);
    }
  }

  const postData = {
    metric: {
      uuid: id,
      message: JSON.stringify(data),
      isError,
      source: 'javascript'
    }
  };

  ApiUtil.post('/metrics/v2/logs', { data: postData });
};
