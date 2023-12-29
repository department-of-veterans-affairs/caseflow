import React from 'react';
import { connect } from 'react-redux';
import { Route, Switch } from 'react-router-dom';
import PropTypes from 'prop-types';
import { LOGO_COLORS } from '../constants/AppConstants';

import AppFrame from '../components/AppFrame';
import CaseSearchLink from '../components/CaseSearchLink';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import NavigationBar from '../components/NavigationBar';
import PageRoute from '../components/PageRoute';
import ScrollToTop from '../components/ScrollToTop';

import CaseflowDistributionAdmin from './admin/components/CaseflowDistributionAdmin';

class CaseflowDistributionApp extends React.PureComponent {
  routedCaseflowDistributionAdmin = (props) => (
    <CaseflowDistributionAdmin {...props.match.params} />
  );

  render = () => (
    <NavigationBar
      wideApp
      defaultUrl={this.props.caseSearchHomePage || this.props.hasCaseDetailsRole ?  '/search' : '/queue'}
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      applicationUrls={this.props.applicationUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT,
      }}
      rightNavElement={<CaseSearchLink />}
      appName="Caseflow Admin"
    >
      <AppFrame wideApp>
        <ScrollToTop />
        <div className="cf-wide-app">
          {this.props.flash && <FlashAlerts flash={this.props.flash} />}

          {/* Base/page (non-modal) routes */}
          <Switch>
            <PageRoute
              path={['/acd-controls', '/case-distribution-controls']}
              title="CaseflowDistribution | Caseflow"
              render={this.routedCaseflowDistributionAdmin}
            />
          </Switch>
        </div>
      </AppFrame>
      <Footer
        wideApp
        appName=""
        feedbackUrl={this.props.feedbackUrl}
        buildDate={this.props.buildDate}
      />
    </NavigationBar>
  );
};

CaseflowDistributionApp.propTypes = {
  applicationUrls: PropTypes.array,
  buildDate: PropTypes.string,
  caseSearchHomePage: PropTypes.bool,
  dropdownUrls: PropTypes.array,
  feedbackUrl: PropTypes.string.isRequired,
  flash: PropTypes.array,
  hasCaseDetailsRole: PropTypes.bool,
  userDisplayName: PropTypes.string.isRequired
};

export default connect()(CaseflowDistributionApp);
