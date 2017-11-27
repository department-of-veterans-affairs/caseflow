import React from 'react';
import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { Provider, connect } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import logger from 'redux-logger';

import ConfigUtil from '../util/ConfigUtil';
import Header from './Header';
import Success from './Success';
import DocumentsCheck from './DocumentsCheck';
import ConfirmHearing from './ConfirmHearing';
import ConfirmCaseDetails from './ConfirmCaseDetails';
import SignAndCertify from './SignAndCertify';
import CertificationProgressBar from './CertificationProgressBar';
import { certificationReducers, mapDataToInitialState } from './reducers/index';
import ErrorMessage from './ErrorMessage';
import PageRoute from '../components/PageRoute';
import ApiUtil from '../util/ApiUtil';
import AsynchronousDataLoader from '../components/AsynchronousDataLoader';
import * as AppConstants from '../constants/AppConstants';
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
  /* eslint class-methods-use-this: ["warn", { "exceptMethods": ["fetchCertificationData","onSuccess", "onError"] }] */

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

  fetchCertificationData(endpoint) {
    return ApiUtil.get(endpoint);
  }

  onSuccess(data) {
    return <Provider store={configureStore(JSON.parse(data.text).certification, JSON.parse(data.text).form9PdfPath)}>
      <div>
        <BrowserRouter>
          <div>
            <Header />
            <CertificationProgressBar />
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
          </div>
        </BrowserRouter>
      </div>
    </Provider>;
  }

  onError() {
    return <StatusMessage
      title="Technical Difficulties">
      Systems that Caseflow Certification connects to are experiencing technical difficulties
      and Caseflow is unable to load.
      We apologize for any inconvenience. Please try again later.
    </StatusMessage>;
  }

  render() {

    const initialMessage = 'Loading and checking documents from the Veteran’s file…';

    const longerThanUsualMessage = 'Documents are taking longer to load than usual. Thanks for your patience!';

    return <div>
      {
        <AsynchronousDataLoader
          componentsPromise={this.fetchCertificationData}
          endpoint={`/certifications/${this.props.vacolsId}`}
          spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_CERTIFICATION}
          pollingIntervalSeconds={AppConstants.CERTIFICATION_DATA_POLLING_INTERVAL}
          message={initialMessage}
          extendedWaitMessage={longerThanUsualMessage}
          showExtendedWaitMessageInSeconds={AppConstants.LONGER_THAN_USUAL_TIMEOUT}
          onSuccess={this.onSuccess}
          onError={this.onError}
          showErrorMessageInSeconds={AppConstants.CERTIFICATION_DATA_OVERALL_TIMEOUT}
        />
      }
    </div>;
  }
}