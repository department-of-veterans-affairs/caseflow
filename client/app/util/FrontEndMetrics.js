import ApiUtil from './ApiUtil';

const INTERVAL_TO_SEND_METRICS = 60000;

let isInitialized = false;
let histograms = [];

const sendHistogram = () => {
  if (histograms.length === 0) {
    return;
  }

  const histogramsCopy = histograms;

  histograms = [];

  ApiUtil.post('/metrics/v1/histogram', { data: { histograms: ApiUtil.convertToSnakeCase(histogramsCopy) } });
};

const initialize = () => {
  if (!isInitialized) {
    isInitialized = true;

    // Only record values for 1/3 of users.
    if (Math.floor(Math.random() * 3) === 0) {
      // Add jitter to requests
      setTimeout(sendHistogram, INTERVAL_TO_SEND_METRICS + (Math.random() * 5));
    }
  }
};

export const collectHistogram = (data) => {
  initialize();

  histograms.push(data);
};
