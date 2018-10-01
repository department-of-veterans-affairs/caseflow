import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { BrowserRouter } from 'react-router-dom';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import PageRoute from '../components/PageRoute';
import { LOGO_COLORS } from '../constants/AppConstants';
import BuildScheduleContainer from './containers/BuildScheduleContainer';
import BuildScheduleUploadContainer from './containers/BuildScheduleUploadContainer';
import ReviewAssignmentsContainer from './containers/ReviewAssignmentsContainer';
import ListScheduleContainer from './containers/ListScheduleContainer';
import ScrollToTop from '../components/ScrollToTop';

class HearingScheduleApp extends React.PureComponent {

  render = () => <BrowserRouter basename="/hearings">
    <NavigationBar
      wideApp
      defaultUrl="/schedule"
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.HEARING_SCHEDULE.OVERLAP,
        accentColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT
      }}
      appName="Hearing Schedule">
      <AppFrame wideApp>
        <ScrollToTop />
        <div className="cf-wide-app">
          <PageRoute
            exact
            path="/schedule"
            title="Scheduled Hearings"
            component={ListScheduleContainer}
          />
          <PageRoute
            exact
            path="/schedule/build"
            title="Caseflow Hearing Schedule"
            breadcrumb="Build"
            component={BuildScheduleContainer}
          />
          <PageRoute
            exact
            path="/schedule/build/upload"
            title="Upload Files"
            breadcrumb="Upload"
            component={BuildScheduleUploadContainer}
          />
          <PageRoute
            exact
            path="/schedule/build/upload/:schedulePeriodId"
            title="Review Assignments"
            breadcrumb="Review"
            component={ReviewAssignmentsContainer}
          />
        </div>
      </AppFrame>
      <Footer
        wideApp
        appName="Hearing Scheduling"
        feedbackUrl={this.props.feedbackUrl}
        buildDate={this.props.buildDate}
      />
    </NavigationBar>
  </BrowserRouter>;
}

HearingScheduleApp.propTypes = {
  userDisplayName: PropTypes.string,
  feedbackUrl: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
  dropdownUrls: PropTypes.array
};

export default connect()(HearingScheduleApp);
