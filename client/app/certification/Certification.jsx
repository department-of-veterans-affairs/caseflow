import React from 'react';
import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { Provider, connect } from 'react-redux';

import configureStore from '../util/ConfigureStore';
import Header from './Header';
import Success from './Success';
import DocumentsCheck from './DocumentsCheck';
import ConfirmHearing from './ConfirmHearing';
import ConfirmCaseDetails from './ConfirmCaseDetails';
import SignAndCertify from './SignAndCertify';
import CertificationProgressBar from './CertificationProgressBar';
import { certificationReducers, mapDataToInitialState } from './reducers/index';
import ErrorMessage from './ErrorMessage';

const UnconnectedEntryPointRedirect = ({ match }) => {
  return <Redirect to={`/certifications/${match.params.vacols_id}/check_documents`}/>;
};

const mapStateToProps = (state) => ({
  certificationStatus: state.certificationStatus
});

const EntryPointRedirect = connect(
  mapStateToProps
)(UnconnectedEntryPointRedirect);

const Certification = ({ certification }) => {
  const initialState = mapDataToInitialState(certification);
  const store = configureStore({
    reducers: certificationReducers,
    initialState
  });

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers.
    // Changes made to the reducers while developing should be
    // available instantly.
    // Note that this expects the global reducer for each app
    // to be present at reducers/index.
    module.hot.accept('./reducers/index', () => {
      store.replaceReducer(certificationReducers);
    });
  }

  return <Provider store={store}>
    <div>
      <BrowserRouter>
        <div>
        <Header/>
        <CertificationProgressBar/>
        <Route path="/certifications/new/:vacols_id"
          component={EntryPointRedirect}/>
        <Route path="/certifications/:vacols_id/check_documents"
          component={DocumentsCheck}/>
        <Route path="/certifications/:vacols_id/confirm_case_details"
          component={ConfirmCaseDetails}/>
        <Route path="/certifications/:vacols_id/confirm_hearing"
          component={ConfirmHearing}/>
        <Route path="/certifications/:vacols_id/sign_and_certify"
          component={SignAndCertify}/>
        <Route path="/certifications/:vacols_id/success"
          component={Success}/>
        <Route path="/certifications/error"
          component={ErrorMessage}/>
      </div>
      </BrowserRouter>
    </div>
  </Provider>;
};

export default Certification;
