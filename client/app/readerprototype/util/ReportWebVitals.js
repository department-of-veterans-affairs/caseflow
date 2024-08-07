// client/app/readerprototype/util/reportWebVitals.js
import { onFCP } from 'web-vitals';
import { recordAsyncMetrics } from '../../../../client/app/util/Metrics';

const reportWebVitals = (featureToggleEnabled, pageNumber, stats) => {

  const handleMetric = (metric) => {
    const pageMetricData = {
      message: `Page Web Vitals ${pageNumber}`,
      product: 'reader prototype',
      type: 'performance',
      data: { ...metric },
      eventId: null
    };

    recordAsyncMetrics(metric, pageMetricData, true);

    console.log(`**VITALS${pageNumber}`, stats);
  };

  if (featureToggleEnabled) {
    onFCP(handleMetric);
  }
};

export default reportWebVitals;
