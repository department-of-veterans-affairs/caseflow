import React from 'react';
import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore } from 'redux';

import DocumentsCheck from './DocumentsCheck';
import AlreadyCertified from './AlreadyCertified';
import NotReady from './NotReady';
import ConfirmHearing from './ConfirmHearing';
import SignAndCertify from './SignAndCertify';
import CertificationProgressBar from './CertificationProgressBar';
import certificationReducers from './reducers/specialIssues';

// TODO: rethink routes, this may be a temporary solution.
// do we want to still use vacols_id?
// what do we want the actual routes to be?
const EntryPointRedirect = ({ match }) => {
  return <Redirect to={`/certifications/${match.params.vacols_id}/check_documents`}/>;
};

const Certification = ({ certification }) => {
  let store = createStore(certificationReducers, certification);

  return <Provider store={store}>
    <div>
      <BrowserRouter>
        <div>
        <CertificationProgressBar/>
        <Route path="/certifications/new/:vacols_id"
          component={EntryPointRedirect}/>
          {/* TODO: Right now we're still using Rails to render the pages
          we display in scenarios where the appeal is not ready
          for certification (e.g. mismatched documents, already certified appeal).
          when we finish implementing the rest of certification v2,
          port those over here */}
        <Route path="/certifications/:vacols_id/check_documents"
          component={DocumentsCheck}/>
        <Route path="/certifications/:vacols_id/confirm_hearing"
          component={ConfirmHearing}/>
        <Route path="/certifications/:vacols_id/sign_and_certify"
          component={SignAndCertify}/>
        <Route path="/certifications/:vacols_id/already_certified"
          component={AlreadyCertified}/>
        <Route path="/certifications/:vacols_id/not_ready"
          component={NotReady}/>
        <Route path="/certifications/:vacols_id/mismatched_documents"
          component={DocumentsCheck}/>
          {/* TODO: should we add the cancel certification link
          and continue links here, or keep them on their own page? */}
      </div>
      </BrowserRouter>
    </div>
  </Provider>;
};

export default Certification;
