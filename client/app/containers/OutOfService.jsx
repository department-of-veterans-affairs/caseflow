import React from 'react';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';

const OutOfService = (props) => <BrowserRouter>
  <div>
    <NavigationBar
      dropdownUrls={props.dropdownUrls}
      appName="Out Of Service"
      userDisplayName="Menu"
      defaultUrl="/"
      logoProps={{
        accentColor: COLORS.GREY_DARK,
        overlapColor: COLORS.GREY_DARK
      }} />
    <AppFrame>
      <StatusMessage title= "Technical Difficulties">
       It looks like Caseflow is experiencing technical difficulties right now.
       We apologize for any inconvenience. Please check back in a little bit.
      </StatusMessage>
    </AppFrame>
    <Footer
      appName="Out Of Service"
      feedbackUrl={props.feedbackUrl}
      buildDate={props.buildDate} />
  </div>
</BrowserRouter>;

export default OutOfService;
