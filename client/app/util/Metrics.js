import ApiUtil from './ApiUtil';
import _ from 'lodash';
import moment from 'moment';

const INTERVAL_TO_SEND_METRICS_MS = moment.duration(1, 'second');

let histograms = [];

const sendHistogram = () => {
  if (histograms.length === 0) {
    return;
  }

  ApiUtil.post('/metrics/v1/histogram', { data: { histograms: ApiUtil.convertToSnakeCase(histograms) } });
  histograms = [];
};

const initialize = _.once(() => {
  // Only record values for a sample of our users.
  if (_.random(0, 0) === 0) {
    // Add jitter to requests
    setInterval(sendHistogram, INTERVAL_TO_SEND_METRICS_MS + _.random(0, moment.duration(5, 'seconds')));
  }
});

export const collectHistogram = (data) => {
  initialize();

  histograms.push(data);
};
