import React from 'react';
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
import HearingDetailsContainer from './containers/DetailsContainer';
import ScrollToTop from '../components/ScrollToTop';

export default class HearingScheduleApp extends React.PureComponent {
  userPermissionProps = () => {
    const {
      userRoleAssign,
      userRoleBuild,
      userInHearingsOrganization
    } = this.props;

    return {
      userRoleAssign,
      userRoleBuild,
      userInHearingsOrganization
    };
  };

  propsForAssignHearingsContainer = () => {
    const {
      userId,
      userCssId
    } = this.props;

    return {
      userId,
      userCssId
    };
  };

  routeForListScheduleContainer = () => <ListScheduleContainer {...this.userPermissionProps()} />;
  routeForAssignHearingsContainer = () => <AssignHearingsContainer {...this.propsForAssignHearingsContainer()} />
  routeForDailyDocket = () => <DailyDocketContainer {...this.userPermissionProps()} />;
  routeForHearingDetails = ({ match: { params }, history }) =>
    <HearingDetailsContainer hearingId={params.hearingId} history={history} {...this.userPermissionProps()} />;

  render = () => <BrowserRouter basename="/hearings">
    <NavigationBar
      wideApp
      defaultUrl="/schedule"
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      applicationUrls={this.props.applicationUrls}
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
            path="/:hearingId/details"
            title="Hearing Details"
            render={this.routeForHearingDetails}
          />
          <PageRoute
            exact
            path="/schedule"
            title="Scheduled Hearings"
            render={this.routeForListScheduleContainer}
          />
          <PageRoute
            exact
            path="/schedule/docket/:hearingDayId"
            title="Daily Docket"
            render={this.routeForDailyDocket}
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
            component={this.routeForAssignHearingsContainer}
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
  dropdownUrls: PropTypes.array,
  userRole: PropTypes.string,
  userId: PropTypes.number,
  userCssId: PropTypes.string
};
