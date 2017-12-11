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
    // Generally, forceUpdate is not recommended. The reason we're doing it is that we
    // have a promise start time, and we want to render differently based on how much
    // time has elapsed since then. We could use setState and increment a timeElapsed
    // variable. However, that would essentially store computed state in this.state,
    // which is also not recommended. I chose this approach because I preferred not to
    // store computed state.
    this.intervalId = window.setInterval(this.forceUpdate.bind(this), 100);
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
    const isTimedOut = Date.now() - this.state.promiseStartTimeMs > this.props.timeoutMs;

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

    const isSlow = Date.now() - this.state.promiseStartTimeMs > this.props.slowLoadThresholdMs;
    const loadingScreenProps = { ...this.props.loadingScreenProps };

    if (isSlow) {
      loadingScreenProps.message = this.props.slowLoadMessage;
    }

    return <LoadingScreen {...loadingScreenProps} />;
  }
}

LoadingDataDisplay.propTypes = {
  createLoadPromise: PropTypes.func.isRequired,
  children: PropTypes.element.isRequired
};

LoadingDataDisplay.defaultProps = {
  slowLoadThresholdMs: 15 * 1000,
  timeoutMs: 30 * 1000,
  slowLoadMessage: 'Loading is taking longer than usual...'
};

export default LoadingDataDisplay;
