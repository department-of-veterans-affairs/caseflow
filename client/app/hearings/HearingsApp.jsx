import { BrowserRouter, Switch, useLocation } from 'react-router-dom';
import { detect } from 'detect-browser';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import querystring from 'querystring';

import { HearingsUserContext } from './contexts/HearingsUserContext';
import { LOGO_COLORS } from '../constants/AppConstants';
import AppFrame from '../components/AppFrame';
import AssignHearingsContainer from './containers/AssignHearingsContainer';
import BuildScheduleContainer from './containers/BuildScheduleContainer';
import BuildScheduleUploadContainer from './containers/BuildScheduleUploadContainer';
import DailyDocketContainer from './containers/DailyDocketContainer';
import { TranscriptionSettingsContainer } from './containers/TranscriptionSettingsContainer';
import { HearingDetailsContainer } from './containers/DetailsContainer';
import HearingWorksheetContainer from './containers/HearingWorksheetContainer';
import HearingWorksheetPrintAllContainer from './containers/HearingWorksheetPrintAllContainer';
import ListScheduleContainer from './containers/ListScheduleContainer';
import NavigationBar from '../components/NavigationBar';
import PageRoute from '../components/PageRoute';
import ReviewAssignmentsContainer from './containers/ReviewAssignmentsContainer';
import ScrollToTop from '../components/ScrollToTop';
import UnsupportedBrowserBanner from '../components/UnsupportedBrowserBanner';
import { TranscriptionFileDispatchView } from './components/TranscriptionFileDispatchView';
import ConfirmWorkOrderModal from './components/transcriptionProcessing/ConfirmWorkOrderModal';
import { WorkOrderDetails } from './components/WorkOrderDetails';

export default class HearingsApp extends React.PureComponent {
  userPermissionProps = () => {
    const {
      userCanAssignHearingSchedule,
      userCanBuildHearingSchedule,
      userCanViewHearingSchedule,
      userCanVsoHearingSchedule,
      userVsoEmployee,
      userHasHearingPrepRole,
      userInHearingOrTranscriptionOrganization,
      userCanAddVirtualHearingDays,
      userCanViewFnodBadgeInHearings,
      userId,
      userCssId,
      userIsJudge,
      userIsDvc,
      userIsHearingManagement,
      userIsBoardAttorney,
      userIsHearingAdmin,
      userIsNonBoardEmployee
    } = this.props;

    return Object.freeze({
      userCanAssignHearingSchedule,
      userCanBuildHearingSchedule,
      userCanViewHearingSchedule,
      userCanVsoHearingSchedule,
      userVsoEmployee,
      userHasHearingPrepRole,
      userInHearingOrTranscriptionOrganization,
      userCanAddVirtualHearingDays,
      userCanViewFnodBadgeInHearings,
      userId,
      userCssId,
      userIsJudge,
      userIsDvc,
      userIsHearingManagement,
      userIsBoardAttorney,
      userIsHearingAdmin,
      userIsNonBoardEmployee,
    });
  };

  propsForAssignHearingsContainer = () => {
    const {
      userId,
      userCssId,
      mstIdentification,
      pactIdentification,
      legacyMstPactIdentification
    } = this.props;

    return Object.freeze({
      userId,
      userCssId,
      mstIdentification,
      pactIdentification,
      legacyMstPactIdentification
    });
  };

  routeForListScheduleContainer = ({ location, history }) =>
    <ListScheduleContainer location={location} history={history} user={this.userPermissionProps()} />;

  routeForAssignHearingsContainer = () => (
    // Also remove where this gets set in the view. (#11757)
    <AssignHearingsContainer
      {...this.propsForAssignHearingsContainer()}
    />
  );

  routeForDailyDocket = (print, edit = false) => () => (
    <DailyDocketContainer
      user={this.userPermissionProps()}
      print={print}
      editDocket={edit}
    />
  );

  routeForHearingDetails = ({ match: { params }, history }) => (
    <HearingsUserContext.Provider value={this.userPermissionProps()}>
      <HearingDetailsContainer hearingId={params.hearingId} history={history} />
    </HearingsUserContext.Provider>
  );

  routeForHearingWorksheet = () => ({ match: { params } }) =>
    <HearingWorksheetContainer hearingId={params.hearingId} />;
  routeForPrintedHearingWorksheets = (props) => {
    const queryString = querystring.parse(props.location.search.replace(/^\?/, ''));
    const hearingIds = (queryString.hearing_ids || '').split(',').filter(_.negate(_.isEmpty));

    return detect().name === 'chrome' ? <HearingWorksheetPrintAllContainer hearingIds={hearingIds} /> :
      <UnsupportedBrowserBanner appName="Hearings" />;
  };

  routeForTranscriptionFileDispatch = () =>
    <TranscriptionFileDispatchView organizations={this.props.organizations} />

  routeForWorkOrderSummary =() => {
    const location = useLocation();
    const queryParams = new URLSearchParams(location.search);
    const taskNumber = queryParams.get('taskNumber');

    return <WorkOrderDetails taskNumber={taskNumber} />;
  }
  routeForTranscriptionSettings = ({ match: history }) => (
    <HearingsUserContext.Provider value={this.userPermissionProps()}>
      <TranscriptionSettingsContainer history={history} />
    </HearingsUserContext.Provider>
  );

  routeForConfirmWorkOrder = ({ history }) => (
    <HearingsUserContext.Provider value={this.userPermissionProps()}>
      <ConfirmWorkOrderModal history={history} onCancel={() => history.goBack()} />
    </HearingsUserContext.Provider>
  );

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
              path="/schedule/add_hearing_day"
              title="Add Hearing Day"
              render={this.routeForListScheduleContainer}
            />
            <PageRoute
              exact
              path="/schedule/docket/:hearingDayId/edit"
              title="Edit Hearing Day"
              render={this.routeForDailyDocket(false, true)}
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
            <PageRoute
              exact
              path="/transcription_files"
              title="Transcription File Dispatch"
              component={this.routeForTranscriptionFileDispatch}
            />
            <PageRoute
              exact
              path="/find_by_contractor"
              title="Transcription Settings"
              component={this.routeForTranscriptionSettings}
            />
            <PageRoute
              exact
              path="/transcription_work_order/display_wo_summary"
              title="Transcription work order"
              component={this.routeForWorkOrderSummary}
            />
            <PageRoute
              exact
              path="/confirm_work_order"
              title="Confirm Work Order"
              component={this.routeForConfirmWorkOrder}
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
  userCanAssignHearingSchedule: PropTypes.bool,
  userCanBuildHearingSchedule: PropTypes.bool,
  userCanViewHearingSchedule: PropTypes.bool,
  userCanVsoHearingSchedule: PropTypes.bool,
  userHasHearingPrepRole: PropTypes.bool,
  userInHearingOrTranscriptionOrganization: PropTypes.bool,
  userCanAddVirtualHearingDays: PropTypes.bool,
  userCanViewFnodBadgeInHearings: PropTypes.bool,
  userVsoEmployee: PropTypes.bool,
  userRole: PropTypes.string,
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  userIsJudge: PropTypes.bool,
  userIsDvc: PropTypes.bool,
  userIsHearingManagement: PropTypes.bool,
  userIsBoardAttorney: PropTypes.bool,
  userIsHearingAdmin: PropTypes.bool,
  mstIdentification: PropTypes.bool,
  pactIdentification: PropTypes.bool,
  legacyMstPactIdentification: PropTypes.bool,
  userIsNonBoardEmployee: PropTypes.bool,
  organizations: PropTypes.array,
};
