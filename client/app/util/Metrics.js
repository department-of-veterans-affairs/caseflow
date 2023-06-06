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

/**
 * uniqueId should be V4 UUID
 * If a uniqueId is not presented one will be generated for it
 *
 * Data is an object containing information that will be stored in metric_attributes
 *
 * If a message is not provided one will be created based on the data passed in
 *
 * Product is which area of Caseflow did the metric come from: queue, hearings, intake, vha, case_distribution, reader
 *
 */
export const recordMetrics = (uniqueId, data, isError = false, { message, product, start, end, duration }) => {
  let id = uniqueId;
  const type = isError ? 'error' : 'log';
  let metricMessage = message ? message : `${id}\n${data}`;
  const productArea = product ? product : 'caseflow';

  // If a uuid wasn't provided assume that metric also wasn't sent to javascript console and send with UUID to console
  if (!uniqueId) {
    id = uuid.v4();
    if (isError) {
      console.error(metricMessage);
    } else {
      // eslint-disable-next-line no-console
      console.log(metricMessage);
    }
  }

  const postData = {
    metric: {
      uuid: id,
      name: `caseflow.client.${productArea}.${type}`,
      message: metricMessage,
      type,
      product: productArea,
      metric_attributes: JSON.stringify(data),
      sent_to: 'javascript_console',
      start,
      end,
      duration
    }
  };

  ApiUtil.post('/metrics/v2/logs', { data: postData });
};
