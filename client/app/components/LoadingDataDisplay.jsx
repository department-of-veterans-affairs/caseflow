/* eslint-disable no-underscore-dangle */
import React from 'react';
import PropTypes from 'prop-types';
import LoadingScreen from './LoadingScreen';
import StatusMessage from './StatusMessage';
import COPY from '../../COPY';

const PROMISE_RESULTS = {
  SUCCESS: 'SUCCESS',
  FAILURE: 'FAILURE'
};

const accessDeniedTitle = { title: COPY.ACCESS_DENIED_TITLE };
const accessDeniedMsg = <div>
        It looks like you do not have the necessary level of access to view this information.<br />
        Please check with your application administrator before trying again.</div>;

const duplicateNumberTitle = { title: COPY.DUPLICATE_PHONE_NUMBER_TITLE };
const duplicateNumberMsg = <div>
        Duplicate phone numbers documented.<br />
  { COPY.DUPLICATE_PHONE_NUMBER_MESSAGE }</div>;

const itemNotFoundTitle = { title: COPY.INFORMATION_CANNOT_BE_FOUND };
const itemNotFoundMsg = <div>
        We could not find the information you were looking for.<br />
        Please return to the previous page, check the information provided, and try again.</div>;

const DEFAULT_UNKNOWN_ERROR_MSG = (
  <div>
    {COPY.DEFAULT_UNKNOWN_ERROR_MESSAGE}
  </div>
);

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

        let errors;

        if (response.response && response.response.type === 'application/json') {
          errors = response.response.body.errors;
        }

        this.setState({
          promiseResult: PROMISE_RESULTS.FAILURE,
          statusCode: response.status,
          error: errors ? errors[0].title : null
        });
        window.clearInterval(this.intervalId);
        // eslint-disable-next-line no-console
        console.log(response);
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

  // eslint-disable-next-line camelcase
  UNSAFE_componentWillReceiveProps(nextProps) {
    if (this.props.createLoadPromise.toString() !== nextProps.createLoadPromise.toString()) {
      throw new Error("Once LoadingDataDisplay is instantiated, you can't change the createLoadPromise function.");
    }
  }

  errorTitleHelper = (statusCode, error) => {
    switch (statusCode) {
    case 403:
      return error === COPY.DUPLICATE_PHONE_NUMBER_TITLE ? duplicateNumberTitle : accessDeniedTitle;
    case 404:
      return itemNotFoundTitle;
    default:
      return this.props.failStatusMessageProps;
    }
  }

  errorMsgHelper = (statusCode, error) => {
    switch (statusCode) {
    case 403:
      return error === COPY.DUPLICATE_PHONE_NUMBER_TITLE ? duplicateNumberMsg : accessDeniedMsg;
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
      return <ErrorComponent {...this.errorTitleHelper(this.state.statusCode, this.state.error)}>
        {this.errorMsgHelper(this.state.statusCode, this.state.error)}
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
  children: PropTypes.node,
  createLoadPromise: PropTypes.func.isRequired,
  errorComponent: PropTypes.func,
  failStatusMessageChildren: PropTypes.node,
  failStatusMessageProps: PropTypes.object,
  loadingComponent: PropTypes.func,
  loadingComponentProps: PropTypes.object,
  slowLoadMessage: PropTypes.string,
  slowLoadThresholdMs: PropTypes.number,
  timeoutMs: PropTypes.number
};

LoadingDataDisplay.defaultProps = {
  slowLoadThresholdMs: 15 * 1000,
  timeoutMs: Infinity,
  slowLoadMessage: COPY.SLOW_LOADING_MESSAGE,
  loadingComponent: LoadingScreen,
  errorComponent: StatusMessage,
  loadingComponentProps: {},
  failStatusMessageProps: {},
  failStatusMessageChildren: DEFAULT_UNKNOWN_ERROR_MSG
};

export default LoadingDataDisplay;
