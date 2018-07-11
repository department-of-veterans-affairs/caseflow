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
import ListScheduleContainer from './containers/ListScheduleContainer';
import ScrollToTop from '../components/ScrollToTop';

class HearingScheduleApp extends React.PureComponent {

  buildSchedule = () => <BuildScheduleContainer />;

  buildScheduleUpload = () => <BuildScheduleUploadContainer />;

  listSchedule = () => <ListScheduleContainer />;

  render = () => <BrowserRouter basename="/hearings">
    <NavigationBar
      wideApp
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
            path="/schedule/build"
            title="Caseflow Hearing Schedule"
            render={this.buildSchedule}
          />
          <PageRoute
            exact
            path="/schedule"
            title="Scheduled Hearings"
            render={this.listSchedule}
          />
          <PageRoute
            exact
            path="/schedule/build/upload"
            title="Upload Files"
            render={this.buildScheduleUpload}
          />
        </div>
      </AppFrame>
      <Footer
        wideApp
        appName="Hearing Scheduling"
        feedbackUrl={this.props.feedbackUrl}
      />
    </NavigationBar>
  </BrowserRouter>;
}

HearingScheduleApp.propTypes = {
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array
};

export default connect()(HearingScheduleApp);
