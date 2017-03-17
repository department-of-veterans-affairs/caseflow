import React from 'react';
import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import DocumentsCheckSuccess from './DocumentsCheckSuccess';
import ConfirmCaseDetails from './ConfirmCaseDetails';
import SignAndCertify from './SignAndCertify';

// TODO: rethink routes, this may be a temporary solution. do we want to still use vacols_id?
// what do we want the actual routes to be?
const EntryPointRedirect = ({ match }) => {
  return <Redirect to={`/certifications/${match.params.vacols_id}/check_documents`}/>;
}

const Certification = () => {
  return <BrowserRouter>
    <div>
      {/* TODO: add progress bar here */}
      <Route path="/certifications/new/:vacols_id" component={EntryPointRedirect}/>
      {/* TODO: Right we're still using Rails to render the pages that are displayed in scenarios where
        the appeal is not ready for certification (e.g. mismatched documents, already certified appeal)
        but when we finish implementing the rest of certification v2, port those over here */}
      <Route path="/certifications/:vacols_id/check_documents" component={DocumentsCheckSuccess}/>
      <Route path="/certifications/:vacols_id/confirm_case_details" component={ConfirmCaseDetails}/>
      <Route path="/certifications/:vacols_id/sign_and_certify" component={SignAndCertify}/>
    {/* TODO: should we add the cancel certification link and continue links here, or keep them on their own page? */}
    </div>
  </BrowserRouter>;
};

export default Certification;
