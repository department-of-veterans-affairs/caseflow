/* eslint-disable no-underscore-dangle */
import React from 'react';
import PropTypes from 'prop-types';
import LoadingScreen from './LoadingScreen';
import StatusMessage from './StatusMessage';
import COPY from '../../COPY';
import { recordAsyncMetrics } from '../util/Metrics';
import { ExternalLinkIcon } from './icons';
import { css } from 'glamor';
import Link from './Link';

const ICON_POSITION_FIX = css({ position: 'relative', top: 3 });

const PROMISE_RESULTS = {
  SUCCESS: 'SUCCESS',
  FAILURE: 'FAILURE'
};

const ESCALATION_FORM_URL = 'https://leaf.va.gov/VBA/335/sensitive_level_access_request/';

const accessDeniedTitle = { title: COPY.ACCESS_DENIED_TITLE };
const accessDeniedMsg = <div>
  VBA employs a sensitive access system and to access records at any designated level requires approval for the same or
  higher-level access.<br />
  You are receiving this message because you do not have an authorized access level required to view this page.<br />
  <br />
  To request access, please click the button below
  <div>
    <Link href={ESCALATION_FORM_URL}>
      <button className="btn btn-default">Request Access &nbsp;
        <span {...ICON_POSITION_FIX}><ExternalLinkIcon /></span>
      </button>
    </Link>
  </div>
  <br />
  If you have any questions or need assistance with the request form linked above,
  please contact the Restricted Portfolio Management team at
  <a href="mailto:VBA.RPM@va.gov">VBA.RPM@va.gov</a>.
</div>;

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

    const metricData = {
      message: this.props.loadingComponentProps?.message || 'loading screen',
      type: 'performance',
      data: {
        failStatusMessageProps: this.props.failStatusMessageProps,
        loadingComponentProps: this.props.loadingComponentProps,
        slowLoadMessage: this.props.slowLoadMessage,
        slowLoadThresholdMs: this.props.slowLoadThresholdMs,
        timeoutMs: this.props.timeoutMs,
        prefetchDisabled: this.props.prefetchDisabled
      }
    };

    // Promise does not give us a way to "un-then" and stop listening
    // when the component unmounts. So we'll leave this reference dangling,
    // but at least we can use this._isMounted to avoid taking action if necessary.
    recordAsyncMetrics(promise, metricData, this.props.metricsLoadScreen).then(
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

  componentDidUpdate(prevProps) {
    if (this.props.createLoadPromise.toString() !== prevProps.createLoadPromise.toString()) {
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
  timeoutMs: PropTypes.number,
  metricsLoadScreen: PropTypes.bool,
  prefetchDisabled: PropTypes.bool,
  readerPreferences: PropTypes.object,
};

LoadingDataDisplay.defaultProps = {
  slowLoadThresholdMs: 15 * 1000,
  timeoutMs: Infinity,
  slowLoadMessage: COPY.SLOW_LOADING_MESSAGE,
  loadingComponent: LoadingScreen,
  errorComponent: StatusMessage,
  loadingComponentProps: {},
  failStatusMessageProps: {},
  failStatusMessageChildren: DEFAULT_UNKNOWN_ERROR_MSG,
  metricsLoadScreen: false,
};

export default LoadingDataDisplay;
