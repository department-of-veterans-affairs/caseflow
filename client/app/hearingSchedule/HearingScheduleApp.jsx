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
import AssignHearingsContainer from './containers/AssignHearingsContainer';
import DailyDocketContainer from './containers/DailyDocketContainer';
import ScrollToTop from '../components/ScrollToTop';
import CaseDetailsLoadingScreen from "../queue/CaseDetailsLoadingScreen";
import CaseDetailsView from "../queue/CaseDetailsView";

class HearingScheduleApp extends React.PureComponent {

  propsForListScheduleContainer = () => {
    const {
      userRoleAssign,
      userRoleBuild
    } = this.props;

    return {
      userRoleAssign,
      userRoleBuild
    };
  };

  routeForListScheduleContainer = () => <ListScheduleContainer {...this.propsForListScheduleContainer()} />;

  routedQueueDetailWithLoadingScreen = (props) => <CaseDetailsLoadingScreen
    tasks={{}} appealDetails={{}} appealId={props.match.params.appealId}>
    <CaseDetailsView appealId={props.match.params.appealId} />
  </CaseDetailsLoadingScreen>;

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
            render={this.routeForListScheduleContainer}
          />
          <PageRoute
            exact
            path="/schedule/docket/:ro_name/:date"
            title="Daily Docket"
            component={DailyDocketContainer}
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
          <PageRoute
            exact
            path="/schedule/assign"
            title="Assign Hearings"
            breadcrumb="Assign"
            component={AssignHearingsContainer}
          />
          <PageRoute
            exact
            path="/queue/appeals/:appealId"
            title="Case Details | Caseflow"
            breadcrumb="Details"
            render={this.routedQueueDetailWithLoadingScreen}
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
  userRoleAssign: PropTypes.bool,
  userRoleBuild: PropTypes.bool,
  feedbackUrl: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
  dropdownUrls: PropTypes.array
};

export default connect()(HearingScheduleApp);
