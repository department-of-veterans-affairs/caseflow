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
    const promise = this.props.createLoadPromise();

    this.setState({ promiseStartTimeMs: Date.now() });

    // Promise does not give us a way to "un-then" and stop listening 
    // when the component unmounts. So we'll leave this reference dangling,
    // but at least we can use this._isMounted to avoid taking action if necessary.
    promise.then(
      () => {
        if (!this._isMounted) {
          return;
        }

        this.setState({ promiseResult: PROMISE_RESULTS.SUCCESS });
        window.clearInterval(this.intervalId);
      },
      () => {
        if (!this._isMounted) {
          return;
        }

        this.setState({ promiseResult: PROMISE_RESULTS.FAILURE });
        window.clearInterval(this.intervalId);
      }
    );
    this.intervalId = window.setInterval(() => {
      // We are storing computed state here, which is generally an anti-pattern in React.
      // The alternative is to use forceUpdate, but Mark did not want to introduce any
      // forceUpdate usage into the codebase.
      this.setState({
        promiseTimeElapsedMs: Date.now() - this.state.promiseStartTimeMs
      });
    }, 100);
    this._isMounted = true;
  }

  componentWillUnmount() {
    window.clearInterval(this.intervalId);
    this._isMounted = false;
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.createLoadPromise !== nextProps.createLoadPromise) {
      throw new Error("Once LoadingDataDisplay is instantiated, you can't change the createLoadPromise function.");
    }
  }

  render() {
    const isTimedOut = this.state.promiseTimeElapsedMs > this.props.timeoutMs;

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

    const isSlow = this.state.promiseTimeElapsedMs > this.props.slowLoadThresholdMs;
    const loadingScreenProps = { ...this.props.loadingScreenProps };

    if (isSlow) {
      loadingScreenProps.message = this.props.slowLoadMessage;
    }

    return <LoadingScreen {...loadingScreenProps} />;
  }
}

LoadingDataDisplay.propTypes = {
  createLoadPromise: PropTypes.func.isRequired
};

LoadingDataDisplay.defaultProps = {
  slowLoadThresholdMs: 15 * 1000,
  timeoutMs: Infinity,
  slowLoadMessage: 'Loading is taking longer than usual...'
};

export default LoadingDataDisplay;
