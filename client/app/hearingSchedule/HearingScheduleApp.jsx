import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { BrowserRouter } from 'react-router-dom';
import { setUserCssId } from './uiReducer/uiActions';

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

import QueueCaseSearchBar from '../queue/SearchBar';
import CaseListView from '../queue/CaseListView';

class HearingScheduleApp extends React.PureComponent {
  componentDidMount = () => {
    this.props.setUserCssId(this.props.userCssId);
  }

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

  routedCaseSearchResults = (props) => <React.Fragment>
    <QueueCaseSearchBar />
    <CaseListView freshLoadOnNavigate caseflowVeteranId={props.match.params.caseflowVeteranId} />
  </React.Fragment>;

  render = () => <BrowserRouter>
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
            path="/hearings/schedule"
            title="Scheduled Hearings"
            render={this.routeForListScheduleContainer}
          />
          <PageRoute
            exact
            path="/cases/:caseflowVeteranId"
            title="Case Search | Caseflow"
            render={this.routedCaseSearchResults} />
          <PageRoute
            exact
            path="/hearings/schedule/docket/:ro_name/:date"
            title="Daily Docket"
            component={DailyDocketContainer}
          />
          <PageRoute
            exact
            path="/hearings/schedule/build"
            title="Caseflow Hearing Schedule"
            breadcrumb="Build"
            component={BuildScheduleContainer}
          />
          <PageRoute
            exact
            path="/hearings/schedule/build/upload"
            title="Upload Files"
            breadcrumb="Upload"
            component={BuildScheduleUploadContainer}
          />
          <PageRoute
            exact
            path="/hearings/schedule/build/upload/:schedulePeriodId"
            title="Review Assignments"
            breadcrumb="Review"
            component={ReviewAssignmentsContainer}
          />
          <PageRoute
            exact
            path="/hearings/schedule/assign"
            title="Assign Hearings"
            breadcrumb="Assign"
            component={AssignHearingsContainer}
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
  userCssId: PropTypes.string,
  feedbackUrl: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
  dropdownUrls: PropTypes.array
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setUserCssId
}, dispatch);

export default connect(null, mapDispatchToProps)(HearingScheduleApp);
