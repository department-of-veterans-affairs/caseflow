import React from 'react';
import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { Provider, connect } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import logger from 'redux-logger';
import _ from 'lodash';

import ConfigUtil from '../util/ConfigUtil';
import Success from './Success';
import DocumentsCheck from './DocumentsCheck';
import ConfirmHearing from './ConfirmHearing';
import ConfirmCaseDetails from './ConfirmCaseDetails';
import SignAndCertify from './SignAndCertify';
import CancelCertificationConfirmation from './CancelCertificationConfirmation';
import { certificationReducers, mapDataToInitialState } from './reducers/index';
import ErrorMessage from './ErrorMessage';
import PageRoute from '../components/PageRoute';
import ApiUtil from '../util/ApiUtil';
import * as AppConstants from '../constants/AppConstants';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import StatusMessage from '../components/StatusMessage';

class EntryPointRedirect extends React.Component {
  render() {
    let {
      match
    } = this.props;

    return <Redirect to={`/certifications/${match.params.vacols_id}/check_documents`} />;
  }
}

const mapStateToProps = (state) => ({
  certificationStatus: state.certificationStatus
});

export default connect(
  mapStateToProps
)(EntryPointRedirect);

const configureStore = (certification, form9PdfPath) => {

  const middleware = [];

  if (!ConfigUtil.test()) {
    middleware.push(logger);
  }

  // This is to be used with the Redux Devtools Chrome extension
  // https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

  const initialData = mapDataToInitialState(certification, form9PdfPath);

  const store = createStore(
    certificationReducers,
    initialData,
    composeEnhancers(applyMiddleware(...middleware))
  );

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers
    module.hot.accept('./reducers/index', () => {
      store.replaceReducer(certificationReducers);
    });
  }

  return store;
};

export class Certification extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      certification: null,
      form9PdfPath: null
    };

    // Allow test harness to trigger reloads
    window.reloadCertification = () => {
      this.checkCertificationData();
    };
  }

  checkCertificationData() {
    const loadPromise = new Promise((resolve, reject) => {
      const makePollAttempt = () => {
        ApiUtil.get(`/certifications/${this.props.vacolsId}`).
          then(({ text }) => {
            const response = JSON.parse(text);

            if (response.loading_data_failed) {
              reject(new Error('Backend failed to load data'));
            }

            if (response.loading_data) {
              setTimeout(makePollAttempt, AppConstants.CERTIFICATION_DATA_POLLING_INTERVAL);

              return;
            }

            this.setState(_.pick(response, ['certification', 'form9PdfPath']));
            resolve();
          }, reject);
      };

      makePollAttempt();
    });

    this.setState({
      promiseStartTimeMs: Date.now(),
      loadPromise
    });
  }

  componentDidMount() {
    // initial check
    this.checkCertificationData();
  }

  render() {
    // We create this.loadPromise in componentDidMount().
    // componentDidMount() is only called after the component is inserted into the DOM,
    // which means that render() will be called beforehand. My inclination was to use
    // componentWillMount() instead, but React docs tell us not to introduce side-effects
    // in that method. I don't know why that's a bad idea. But this approach lets us
    // keep the side effects in componentDidMount().
    if (!this.state.loadPromise) {
      return null;
    }

    const failureMessage = <StatusMessage title="Technical Difficulties">
      Systems that Caseflow Certification connects to are experiencing technical difficulties
      and Caseflow is unable to load.
      We apologize for any inconvenience. Please try again later.
    </StatusMessage>;

    let successComponent = <div></div>;

    if (this.state.certification) {
      successComponent = <Provider store={configureStore(this.state.certification, this.state.form9PdfPath)}>
        <BrowserRouter>
          <div>
            <Route path="/certifications/new/:vacols_id"
              component={EntryPointRedirect} />
            <PageRoute
              title="Check Documents | Caseflow Certification"
              path="/certifications/:vacols_id/check_documents"
              component={DocumentsCheck}
            />
            <PageRoute
              title="Confirm Case Details | Caseflow Certification"
              path="/certifications/:vacols_id/confirm_case_details"
              component={ConfirmCaseDetails}
            />
            <PageRoute
              title="Confirm Hearing | Caseflow Certification"
              path="/certifications/:vacols_id/confirm_hearing"
              component={ConfirmHearing}
            />
            <PageRoute
              title="Sign and Certify | Caseflow Certification"
              path="/certifications/:vacols_id/sign_and_certify"
              component={SignAndCertify} />
            <PageRoute
              title="Success! | Caseflow Certification"
              path="/certifications/:vacols_id/success"
              component={Success}
            />
            <PageRoute
              title="Error | Caseflow Certification"
              path="/certifications/error"
              component={ErrorMessage}
            />
            <PageRoute
              title="Not Certified | Caseflow Certification"
              path="/certification_cancellations/"
              component={CancelCertificationConfirmation}
            />
          </div>
        </BrowserRouter>
      </Provider>;
    }

    return <LoadingDataDisplay
      loadPromise={this.state.loadPromise}
      promiseStartTimeMs={this.state.promiseStartTimeMs}
      slowLoadMessage="Documents are taking longer to load than usual. Thanks for your patience!"
      loadingScreenProps={{
        message: 'Loading and checking documents from the Veteran’s file…',
        spinnerColor: AppConstants.LOADING_INDICATOR_COLOR_CERTIFICATION
      }}
      successComponent={successComponent}
      failureComponent={failureMessage}
    />;
  }
}
