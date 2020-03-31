import _ from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter, Switch } from 'react-router-dom';
import { detect } from 'detect-browser';
import querystring from 'querystring';
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
import HearingWorksheetContainer from './containers/HearingWorksheetContainer';
import HearingWorksheetPrintAllContainer from './containers/HearingWorksheetPrintAllContainer';
import ScrollToTop from '../components/ScrollToTop';
import UnsupportedBrowserBanner from '../components/UnsupportedBrowserBanner';

export default class HearingsApp extends React.PureComponent {
  userPermissionProps = () => {
    const {
      userCanScheduleVirtualHearings,
      userCanAssignHearingSchedule,
      userCanBuildHearingSchedule,
      userCanViewHearingSchedule,
      userCanVsoHearingSchedule,
      userHasHearingPrepRole,
      userInHearingOrTranscriptionOrganization,
      userId,
      userCssId
    } = this.props;

    return {
      userCanScheduleVirtualHearings,
      userCanAssignHearingSchedule,
      userCanBuildHearingSchedule,
      userCanViewHearingSchedule,
      userCanVsoHearingSchedule,
      userHasHearingPrepRole,
      userInHearingOrTranscriptionOrganization,
      userId,
      userCssId
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

  routeForListScheduleContainer = () => <ListScheduleContainer user={this.userPermissionProps()} />;
  routeForAssignHearingsContainer = () => (
    // Also remove where this gets set in the view. (#11757)
    <AssignHearingsContainer
      {...this.propsForAssignHearingsContainer()}
    />
  );
  routeForDailyDocket = (print) => () => <DailyDocketContainer user={this.userPermissionProps()} print={print} />;
  routeForHearingDetails = ({ match: { params }, history }) =>
    <HearingDetailsContainer hearingId={params.hearingId} history={history} user={this.userPermissionProps()} />;
  routeForHearingWorksheet = () => ({ match: { params } }) =>
    <HearingWorksheetContainer hearingId={params.hearingId} />;
  routeForPrintedHearingWorksheets = (props) => {
    const queryString = querystring.parse(props.location.search.replace(/^\?/, ''));
    const hearingIds = (queryString.hearing_ids || '').split(',').filter(_.negate(_.isEmpty));

    return detect().name === 'chrome' ? <HearingWorksheetPrintAllContainer hearingIds={hearingIds} /> :
      <UnsupportedBrowserBanner appName="Hearings" />;
  };

  render = () => <BrowserRouter basename="/hearings">
    <Switch>
      <PageRoute
        exact
        path="/worksheet/print"
        title="Hearing Worksheet"
        render={this.routeForPrintedHearingWorksheets}
      />
      <PageRoute
        exact
        path="/schedule/docket/:hearingDayId/print"
        title="Daily Docket"
        render={this.routeForDailyDocket(true)}
      />
      <NavigationBar
        wideApp
        defaultUrl="/schedule"
        userDisplayName={this.props.userDisplayName}
        dropdownUrls={this.props.dropdownUrls}
        applicationUrls={this.props.applicationUrls}
        logoProps={{
          overlapColor: LOGO_COLORS.HEARINGS.OVERLAP,
          accentColor: LOGO_COLORS.HEARINGS.ACCENT
        }}
        appName="Hearings">
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
              path="/:hearingId/worksheet"
              title="Hearing Worksheet"
              render={this.routeForHearingWorksheet(false)}
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
              render={this.routeForDailyDocket(false)}
            />
            <PageRoute
              exact
              path="/schedule/build"
              title="Caseflow Hearings"
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
          appName="Hearings"
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate}
        />
      </NavigationBar>
    </Switch>
  </BrowserRouter>;
}

HearingsApp.propTypes = {
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  applicationUrls: PropTypes.array,
  feedbackUrl: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
  userCanScheduleVirtualHearings: PropTypes.bool,
  userCanAssignHearingSchedule: PropTypes.bool,
  userCanBuildHearingSchedule: PropTypes.bool,
  userCanViewHearingSchedule: PropTypes.bool,
  userCanVsoHearingSchedule: PropTypes.bool,
  userHasHearingPrepRole: PropTypes.bool,
  userInHearingOrTranscriptionOrganization: PropTypes.bool,
  userRole: PropTypes.string,
  userId: PropTypes.number,
  userCssId: PropTypes.string
};
