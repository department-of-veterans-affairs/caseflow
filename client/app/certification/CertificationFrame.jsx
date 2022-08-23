import React from 'react';
import { BrowserRouter, Route } from 'react-router-dom';
import { connect } from 'react-redux';

import Success from './Success';
import DocumentsCheck from './DocumentsCheck';
import ConfirmHearing from './ConfirmHearing';
import ConfirmCaseDetails from './ConfirmCaseDetails';
import SignAndCertify from './SignAndCertify';
import EntryPointRedirect from './components/EntryPointRedirect';
import CancelCertificationConfirmation from './CancelCertificationConfirmation';
import ErrorMessage from './components/ErrorMessage';
import PageRoute from '../components/PageRoute';
import PerformanceDegradationBanner from '../components/PerformanceDegradationBanner';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { LOGO_COLORS } from '../constants/AppConstants';

class CertificationFrame extends React.Component {

  render() {

    return <BrowserRouter>
      <div>
        <NavigationBar
          wideApp
          defaultUrl="/"
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          logoProps={{
            overlapColor: LOGO_COLORS.CERTIFICATION.OVERLAP,
            accentColor: LOGO_COLORS.CERTIFICATION.ACCENT
          }}
          appName="Certification" />
        <PerformanceDegradationBanner />
        <AppFrame>
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
        </AppFrame>
        <Footer
          wideApp
          appName="Certification"
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate}
        />
      </div>
    </BrowserRouter>;
  }
}

const mapStateToProps = (state) => ({
  certificationStatus: state.certificationStatus
});

export default connect(mapStateToProps)(CertificationFrame);