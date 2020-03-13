import ReactPolling from 'react-polling';
import Proptypes from 'prop-types';

export default class ExponentialPolling extends ReactPolling {
  initConfig(options){
    super.initConfig(options);
    this.config.backoffMultiplier = options.backoffMultiplier;
  }

  runPolling() {
    super.runPolling();
    this.config.interval *= this.config.backoffMultiplier;
  }
}

ExponentialPolling.propTypes = {
  backoffMultiplier: Proptypes.number
};

ExponentialPolling.defaultProps = {
  backoffMultiplier: 2
};