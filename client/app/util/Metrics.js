import ApiUtil, { postMetricLogs } from './ApiUtil';
import _ from 'lodash';
import moment from 'moment';
import uuid from 'uuid';

// ------------------------------------------------------------------------------------------
// Metric Storage and recording
// ------------------------------------------------------------------------------------------

const metricMessage = (uniqueId, data, message) => message ? message : `${uniqueId}\n${data}`;

/**
 * If a uuid wasn't provided assume that metric also wasn't sent to javascript console
 * and send with UUID to console
 */
const checkUuid = (uniqueId, data, message, type) => {
  let id = uniqueId;
  const isError = type === 'error';

  if (!uniqueId) {
    id = uuid.v4();
    const logFn = isError ? console.error : console.log;
    logFn(metricMessage(id, data, message));
  }

  return id;
};

/**
 * uniqueId should be V4 UUID
 * If a uniqueId is not presented one will be generated for it
 * Data is an object containing information that will be stored in metric_attributes
 * If a message is not provided one will be created based on the data passed in
 * Product is which area of Caseflow did the metric come from: queue, hearings, intake, vha, case_distribution, reader
 */
export const storeMetrics = (uniqueId, data, {
  message,
  type = 'log',
  product,
  start: start || new Date().toISOString(),
  end: end || new Date().toISOString(),
  duration: duration || 0,
  additional_info: additionalInfo || {}
}, eventId = null) => {
  const metricType = ['log', 'error', 'performance'].includes(type) ? type : 'log';
  const productArea = product ? product : 'caseflow';

  const postData = {
    metric: {
      uuid: uniqueId,
      event_id: eventId,
      name: `caseflow.client.${productArea}.${metricType}`,
      message: metricMessage(uniqueId, data, message),
      type: metricType,
      product: productArea,
      metric_attributes: JSON.stringify(data),
      sent_to: 'javascript_console',
      start,
      end,
      duration,
      additional_info: additionalInfo
    }
  };

  // eslint-disable-next-line no-console
  console.info(`EVENT_ID: ${eventId} ${message}`);

  postMetricLogs(postData);
};

export const recordMetrics = (targetFunction, { uniqueId, data, message, type = 'log', product, eventId = null, additionalInfo },
  saveMetrics = true) => {

  let id = checkUuid(uniqueId, data, message, type);

  const t0 = performance.now();
  const start = new Date(performance.timeOrigin + t0);
  const name = targetFunction?.name || message;

  // eslint-disable-next-line no-console
  console.info(`STARTED: ${id} ${name}`);
  const result = () => targetFunction();
  const t1 = performance.now();
  const end = new Date(performance.timeOrigin + t1);

  const duration = t1 - t0;

  // eslint-disable-next-line no-console
  console.info(`FINISHED: ${id} ${name} in ${duration} milliseconds`);

  if (saveMetrics) {
    console.info(`SAVING METRICS: ${id}`);
    const metricData = {
      ...data,
      name
    };

    storeMetrics(id, metricData, { message, type, product, start, end, duration, additionalInfo }, eventId);
  } else {
    console.warn(`METRICS NOT SAVED: ${id}`);
  }

  return result;
};

/**
 * Hopefully this doesn't cause issues and preserves the async of the promise or async function
 *
 * Might need to split into async and promise versions if issues
 */
export const recordAsyncMetrics = async (promise, { uniqueId, data, message, type = 'log', product, eventId, additionalInfo },
  saveMetrics = true) => {

  let id = checkUuid(uniqueId, data, message, type);

  const t0 = performance.now();
  const start = new Date(performance.timeOrigin + t0);
  const name = message || promise;

  // eslint-disable-next-line no-console
  console.info(`STARTED: ${id} ${name}`);
  const prom = () => promise;
  const result = await prom().catch((error) => {
    console.error(`ERROR: ${id} ${name}`, error);
    throw error;
  });
  const t1 = performance.now();
  const end = new Date(performance.timeOrigin + t1);

  const duration = t1 - t0;

  // eslint-disable-next-line no-console
  console.info(`FINISHED: ${id} ${name} in ${duration} milliseconds`);

  if (saveMetrics) {
    const metricData = {
      ...data,
      name
    };

    storeMetrics(uniqueId, metricData, { message, type, product, start, end, duration, additionalInfo }, eventId);
  }

  return result;
};

// ------------------------------------------------------------------------------------------
// Histograms
// ------------------------------------------------------------------------------------------

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

  const id = uuid.v4();
  const metricsData = data;
  const time = Date(Date.now()).toString();
  const readerData = {
    message: `Render document content for "${ data.attrs.documentType }"`,
    type: 'performance',
    product: 'pdfjs.document.render',
    start: time,
    end: Date(Date.now()).toString(),
    duration: data.value,
  };

  if (data.value > 0 || data.attrs.pageCount <2) {
    storeMetrics(id, metricsData, readerData);
  } else {
    console.warn(`HISTOGRAM NOT COLLECTED: ${id}`);
  }
};

