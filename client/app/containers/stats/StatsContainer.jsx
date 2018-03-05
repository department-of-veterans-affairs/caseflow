import React from 'react';
import AppFrame from '../../components/AppFrame';
import NavigationBar from '../../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';

const StatsContainer = (props) => <BrowserRouter>
  <React.Fragment>
    <NavigationBar
      dropdownUrls={props.dropdownUrls}
      appName="Stats"
      userDisplayName={props.userDisplayName}
      defaultUrl="/"
      logoProps={{
        accentColor: COLORS.GREY_DARK,
        overlapColor: COLORS.GREY_DARK
      }} />
    <AppFrame>
      <main className="cf-app-segment cf-app-segment--alt">
        <h2>Caseflow Stats</h2>

        <ul>
          <li>
            <a href="/certification/stats">Certification Stats</a>
          </li>
          <li>
            <a href="/dispatch/stats">Dispatch Stats</a>
          </li>
          <li>
            <a href="/intake/stats">Intake Stats</a>
          </li>
        </ul>
      </main>
    </AppFrame>
    <Footer
      appName="Stats"
      feedbackUrl={props.feedbackUrl}
      buildDate={props.buildDate} />
  </React.Fragment>
</BrowserRouter>;

export default StatsContainer;
