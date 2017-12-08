/* eslint-disable no-underscore-dangle */
import React from 'react';
import PropTypes from 'prop-types';
import LoadingScreen from './LoadingScreen';
import StatusMessage from './StatusMessage';

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
    this._isMounted = true;
  }

  componentWillUnmount() {
    window.clearInterval(this.intervalId);
    this._isMounted = false;
  }

  listenToPromise = (promise) => {
    // Promise does not give us a way to "un-then" and stop listening 
    // when the component unmounts. So we'll leave this reference dangling,
    // but at least we can use this.isMounted to avoid taking action if necessary.
    promise.then(
      () => {
        if (this._isMounted && !promise === this.props.loadPromise) {
          return;
        }

        this.setState({ promiseResult: PROMISE_RESULTS.SUCCESS });
        window.clearInterval(this.intervalId);
      },
      () => {
        if (this._isMounted && !promise === this.props.loadPromise) {
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
    const isTimedOut = Date.now() - this.props.promiseStartTimeMs > this.props.timeoutMs;

    // Because we put this first, we'll show the error state if the timeout has elapsed,
    // even if the promise did eventually resolve.
    if (this.state.promiseResult === PROMISE_RESULTS.FAILURE || isTimedOut) {
      return <StatusMessage {...this.props.failStatusMessageProps}>
        {this.props.failStatusMessageChildren}
      </StatusMessage>;
    }

    if (this.state.promiseResult === PROMISE_RESULTS.SUCCESS) {
      return this.props.children;
    }

    const isSlow = Date.now() - this.props.promiseStartTimeMs > this.props.slowLoadThresholdMs;
    const loadingScreenProps = { ...this.props.loadingScreenProps };

    if (isSlow) {
      loadingScreenProps.message = this.props.slowLoadMessage;
    }

    return <LoadingScreen {...loadingScreenProps} />;
  }
}

LoadingDataDisplay.propTypes = {
  loadPromise: PropTypes.object.isRequired
};

LoadingDataDisplay.defaultProps = {
  slowLoadThresholdMs: 15 * 1000,
  timeoutMs: 30 * 1000,
  slowLoadMessage: 'Loading is taking longer than usual...'
};

export default LoadingDataDisplay;
