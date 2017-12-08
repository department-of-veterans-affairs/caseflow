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
    this.cancelInterval = setInterval(this.forceUpdate.bind(this), 100);
  }

  componentWillUnmount() {
    this.cancelInterval();
  }

  listenToPromise = (promise) => {
    // TODO These promise handlers may fire after the component unmounts.
    promise.then(
      () => {
        if (!promise === this.props.loadPromise) {
          return;
        }

        this.setState({ promiseResult: PROMISE_RESULTS.SUCCESS });
      },
      () => {
        if (!promise === this.props.loadPromise) {
          return;
        }

        this.setState({ promiseResult: PROMISE_RESULTS.FAILURE });
      }
    );
  }

  componentWillReceiveProps(nextProps) {
    this.listenToPromise(nextProps.loadPromise);
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

    return <LoadingScreen message={message} {...this.props.loadingScreenProps} />;
  }
}

LoadingDataDisplay.propTypes = {
  loadPromise: PropTypes.object.isRequired
};

export default LoadingDataDisplay;
