import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import PageRoute from '../components/PageRoute';
import { LOGO_COLORS } from '../constants/AppConstants';
import BuildScheduleContainer from './containers/BuildScheduleContainer';
import ScrollToTop from '../components/ScrollToTop';

const HearingSchedule = ({ hearingSchedule }) => {
  return <BrowserRouter>
    <NavigationBar
      wideApp
      userDisplayName={hearingSchedule.userDisplayName}
      dropdownUrls={hearingSchedule.dropdownUrls}
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
            path="/hearings/schedule/build"
            title="Caseflow"
            component={BuildScheduleContainer}
          />
        </div>
      </AppFrame>
      <Footer
        wideApp
        appName="Hearing Scheduling"
        feedbackUrl={hearingSchedule.feedbackUrl}
      />
    </NavigationBar>
  </BrowserRouter>;
};

export default HearingSchedule;
