import React from 'react';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';

const options = [{ title: 'Help',
  link: '/help' },
{ title: 'Switch User',
  link: '/test/users' }];

const Unauthorized = (props) => <BrowserRouter>
  <div>
    <NavigationBar
      dropdownUrls={options}
      appName="Unauthorized"
      userDisplayName="Menu"
      defaultUrl="/"
      logoProps={{
        accentColor: COLORS.GREY_DARK,
        overlapColor: COLORS.GREY_DARK
      }} />
    <AppFrame>
      <StatusMessage title= "Drat!">
             You aren't authorized to use this part of Caseflow yet.
        { props.dependenciesFaked &&
            <p className="cf-msg-screen-text">
              <a href="/test/users">
              Switch users to access this page.
              </a>
            </p>}
      </StatusMessage>
    </AppFrame>
    <Footer
      appName="Unauthorized"
      feedbackUrl={props.feedbackUrl}
      buildDate={props.buildDate} />
  </div>
</BrowserRouter>;

export default Unauthorized;

