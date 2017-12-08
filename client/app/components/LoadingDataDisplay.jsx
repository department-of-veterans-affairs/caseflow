import React from 'react';
import PropTypes from 'prop-types';
import LoadingScreen from '../components/LoadingScreen';

const PROMISE_RESULTS = {
  SUCCESS: 'SUCCESS',
  FAILURE: 'FAILURE'
};

class LoadingDataDisplay extends React.PureComponent {
  constructor() {
    super();
    this.state = {};
  }

  componentDidMount() {
    this.listenToPromise(this.props.loadPromise);
    this.intervalId = window.setInterval(this.forceUpdate.bind(this), 100);
  }

  componentWillUnmount() {
    this.intervalId();
  }

  listenToPromise = (promise) => {
    // TODO These promise handlers may fire after the component unmounts.
    promise.then(
      () => {
        if (!promise === this.props.loadPromise) {
          return;
        }

        this.setState({ promiseResult: PROMISE_RESULTS.SUCCESS });
        window.clearInterval(this.intervalId);
      },
      () => {
        if (!promise === this.props.loadPromise) {
          return;
        }
        
        this.setState({ promiseResult: PROMISE_RESULTS.FAILURE });
        window.clearInterval(this.intervalId);
      }
    );
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.loadPromise !== nextProps.loadPromise) {
      this.listenToPromise(nextProps.loadPromise);
    }
  }

  render() {
    if (this.state.promiseResult === PROMISE_RESULTS.SUCCESS) {
      return this.props.successComponent;
    }
    
    const isTimedOut = Date.now() - this.props.promiseStartTimeMs > this.props.timeoutMs;
    
    if (this.state.promiseResult === PROMISE_RESULTS.FAILURE || isTimedOut) {
      return this.props.failureComponent;
    }
    
    const isSlow = Date.now() - this.props.promiseStartTimeMs > this.props.slowLoadThresholdMs;
    // eslint-disable-next-line no-undefined
    const message = isSlow ? this.props.slowLoadMessage : undefined;
    console.log('render', isSlow, Date.now() - this.props.promiseStartTimeMs, this.props.slowLoadThresholdMs);

    return <LoadingScreen {...this.props.loadingScreenProps} message={message} />;
  }
}

LoadingDataDisplay.propTypes = {
  loadPromise: PropTypes.object.isRequired,
  successComponent: PropTypes.element.isRequired,
  failureComponent: PropTypes.element.isRequired
};

export default LoadingDataDisplay;
