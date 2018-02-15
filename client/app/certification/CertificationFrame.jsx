import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

import { BrowserRouter, Route, Redirect } from 'react-router-dom';
import { connect } from 'react-redux';
import _ from 'lodash';

import Success from './Success';
import DocumentsCheck from './DocumentsCheck';
import ConfirmHearing from './ConfirmHearing';
import ConfirmCaseDetails from './ConfirmCaseDetails';
import SignAndCertify from './SignAndCertify';
import EntryPointRedirect from './components/EntryPointRedirect'
import CancelCertificationConfirmation from './CancelCertificationConfirmation';
import { certificationReducers, mapDataToInitialState } from './reducers/index';
import ErrorMessage from './ErrorMessage';
import PageRoute from '../components/PageRoute';
import ApiUtil from '../util/ApiUtil';
import * as AppConstants from '../constants/AppConstants';
import LoadingDataDisplay from '../components/LoadingDataDisplay';




 class CertificationFrame extends React.Component {


  render() {

    return <BrowserRouter>
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
          </BrowserRouter>;
  }
}

const mapStateToProps = (state) => ({
  certificationStatus: state.certificationStatus
});
export default connect(mapStateToProps)(CertificationFrame);