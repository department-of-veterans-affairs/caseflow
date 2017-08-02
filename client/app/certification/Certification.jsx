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
import LoadingScreen from '../components/LoadingScreen';
import * as AppConstants from '../constants/AppConstants';
import StatusMessage from '../components/StatusMessage';

const UnconnectedEntryPointRedirect = ({ match }) => {
  return <Redirect to={`/certifications/${match.params.vacols_id}/check_documents`}/>;
};

const mapStateToProps = (state) => ({
  certificationStatus: state.certificationStatus
});

const EntryPointRedirect = connect(
  mapStateToProps
)(UnconnectedEntryPointRedirect);

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

export default class Certification extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      loadingData: true,
      loadingDataFailed: false,
      certification: null,
      form9PdfPath: null,
      longerThanUsual: false,
      overallTimeout: false
    };
  }

  checkCertificationData() {
    ApiUtil.get(`/certifications/${this.props.vacols_id}`).
    then((data) => {
      this.setState({
        loadingData: JSON.parse(data.text).loading_data,
        loadingDataFailed: JSON.parse(data.text).loading_data_failed,
        certification: JSON.parse(data.text).certification,
        form9PdfPath: JSON.parse(data.text).form9PdfPath
      });
    }, () => {
      this.setState({
        loadingDataFailed: true
      });
    });
  }

  componentDidMount() {
    // initial check
    this.checkCertificationData();
    // Timer for longer-than-usual message
    setTimeout(
        () => {
          this.setState(
            Object.assign({}, this.state, {
              longerThanUsual: true
            }));
        },
        AppConstants.LONGER_THAN_USUAL_TIMEOUT
      );
    // Timer for overall timeout
    setTimeout(
        () => {
          this.setState(
            Object.assign({}, this.state, {
              overallTimeout: true
            }));
        },
        AppConstants.CERTIFICATION_DATA_OVERALL_TIMEOUT
      );
  }

  componentDidUpdate() {
    // subsequent checks if data is still loading
    if (!this.state.certification && !this.state.loadingDataFailed && !this.state.overallTimeout) {
      setTimeout(() =>
       this.checkCertificationData(), AppConstants.CERTIFICATION_DATA_POLLING_INTERVAL);
    }
  }


  render() {

    const initialMessage = 'Loading and checking documents from the Veteran’s file…';

    const longerThanUsualMessage = 'Documents are taking longer to load than usual. Thanks for your patience!';

    const failureMessage = <StatusMessage
                              title="Technical Difficulties">
                              Systems that Caseflow Certification connects to are experiencing technical difficulties
                              and Caseflow is unable to load.
                We apologize for any inconvenience. Please try again later.
               </StatusMessage>;

    let message = this.state.longerThanUsual ? longerThanUsualMessage : initialMessage;

    return <div>
    {
      !(this.state.certification || this.state.loadingDataFailed || this.state.overallTimeout) &&
        <LoadingScreen
          message={message}
          spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_CERTIFICATION}/>
    }

    {
      (this.state.loadingDataFailed || this.state.overallTimeout) && !this.state.certification && failureMessage
    }

    { this.state.certification &&
      <Provider store={configureStore(this.state.certification, this.state.form9PdfPath)}>
        <div>
          <BrowserRouter>
            <div>
            <Header/>
            <CertificationProgressBar/>
            <Route path="/certifications/new/:vacols_id"
              component={EntryPointRedirect}/>
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
              component={SignAndCertify}/>
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
      </Provider> }
    </div>;
  }
}
