import React from 'react';
import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { Provider, connect } from 'react-redux';
import logger from 'redux-logger';

import ConfigUtil from '../util/ConfigUtil';
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
  const middleware = [logger];
  const reducers = certificationReducers;
  const store = configureStore({
    reducers,
    initialState,
    middleware
  });

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
          {/* TODO: should we add the cancel certification link
          and continue links here, or keep them on their own page? */}
      </div>
      </BrowserRouter>
    </div>
  </Provider>;
};

export default Certification;
