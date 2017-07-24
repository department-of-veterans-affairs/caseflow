import Perf from 'react-addons-perf';
import _ from 'lodash';

export default _.once(() => {
  let isMeasuringPerf = false;

  // eslint-disable-next-line max-statements
  const handleStartPerfMeasurement = (event) => {
    if (!(event.altKey && event.code === 'KeyP')) {
      return;
    }
    /* eslint-disable no-console */

    // eslint-disable-next-line no-negated-condition
    if (!isMeasuringPerf) {
      Perf.start();
      console.log('Started React perf measurements');
      isMeasuringPerf = true;
    } else {
      Perf.stop();
      isMeasuringPerf = false;

      const measurements = Perf.getLastMeasurements();

      console.group('Stopped measuring React perf. (If nothing re-rendered, nothing will show up.) Results:');
      Perf.printInclusive(measurements);
      Perf.printWasted(measurements);
      console.groupEnd();
    }
    /* eslint-enable no-console */
  }

  window.addEventListener('keydown', handleStartPerfMeasurement);

});
