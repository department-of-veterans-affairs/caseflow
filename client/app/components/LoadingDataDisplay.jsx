/* eslint-disable no-underscore-dangle */
import React from 'react';
import PropTypes from 'prop-types';
import LoadingScreen from './LoadingScreen';
import StatusMessage from './StatusMessage';

const PROMISE_RESULTS = {
  SUCCESS: 'SUCCESS',
  FAILURE: 'FAILURE'
};

const accessDeniedTitle = { title: 'Additional access needed' };
const accessDeniedMsg = <div>
        It looks like you do not have the necessary level of access to view this information.<br />
        Please check with your application administrator before trying again.</div>;

const itemNotFoundTitle = { title: 'Information cannot be found' };
const itemNotFoundMsg = <div>
        We could not find the information you were looking for.<br />
        Please return to the previous page, check the information provided, and try again.</div>;

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

        this.setState({ promiseResult: PROMISE_RESULTS.SUCCESS,
          statusCode: 200 });
        window.clearInterval(this.intervalId);
      },
      (response) => {
        if (!this._isMounted) {
          return;
        }

        this.setState({ promiseResult: PROMISE_RESULTS.FAILURE,
          statusCode: response.status });
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

  errorTitleHelper = (statusCode) => {
    switch (statusCode) {
    case 403:
      return accessDeniedTitle;
    case 404:
      return itemNotFoundTitle;
    default:
      return this.props.failStatusMessageProps;
    }
  }

  errorMsgHelper = (statusCode) => {
    switch (statusCode) {
    case 403:
      return accessDeniedMsg;
    case 404:
      return itemNotFoundMsg;
    default:
      return this.props.failStatusMessageChildren;
    }
  }

  render() {
    const {
      loadingComponent: LoadingComponent,
      errorComponent: ErrorComponent
    } = this.props;
    const isTimedOut = this.state.promiseTimeElapsedMs > this.props.timeoutMs;

    // Because we put this first, we'll show the error state if the timeout has elapsed,
    // even if the promise did eventually resolve.
    if (this.state.promiseResult === PROMISE_RESULTS.FAILURE || isTimedOut) {
      return <ErrorComponent {...this.errorTitleHelper(this.state.statusCode)}>
        {this.errorMsgHelper(this.state.statusCode)}
      </ErrorComponent>;
    }

    if (this.state.promiseResult === PROMISE_RESULTS.SUCCESS) {
      return this.props.children;
    }

    const isSlow = this.state.promiseTimeElapsedMs > this.props.slowLoadThresholdMs;
    const loadingComponentProps = { ...this.props.loadingComponentProps };

    if (isSlow) {
      loadingComponentProps.message = this.props.slowLoadMessage;
    }

    return <LoadingComponent {...loadingComponentProps} />;
  }
}

LoadingDataDisplay.propTypes = {
  createLoadPromise: PropTypes.func.isRequired,
  loadingComponentProps: PropTypes.object,
  failStatusMessageProps: PropTypes.object,
  failStatusMessageChildren: PropTypes.object
};

LoadingDataDisplay.defaultProps = {
  slowLoadThresholdMs: 15 * 1000,
  timeoutMs: Infinity,
  slowLoadMessage: 'Loading is taking longer than usual...',
  loadingComponent: LoadingScreen,
  errorComponent: StatusMessage,
  loadingComponentProps: {},
  failStatusMessageProps: {},
  failStatusMessageChildren: {}
};

export default LoadingDataDisplay;
