import React from 'react';
import PropTypes from 'prop-types';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from 'app/components/StatusMessage';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';

const Feedback = (props) => <BrowserRouter>
  <div>
    <NavigationBar
      dropdownUrls={props.dropdownUrls}
      appName="Feedback"
      userDisplayName="Menu"
      defaultUrl="/"
      logoProps={{
        accentColor: COLORS.GREY_DARK,
        overlapColor: COLORS.GREY_DARK
      }} />
    <AppFrame>
      <StatusMessage title="Having a technical difficulty?" messageTag="p" >
        <p tabIndex={0}>
          Submit a ticket to the Caseflow team using <a href="https://yourIT.va.gov" target="_blank"
            rel="noopener noreferrer">YourIT</a>. The YourIT link is also available on most VA issued workstations.
          To better assist, please ensure you provide the URL or web address associated to the issue in the ticket.
        </p>
        <p tabIndex={0}>
          The Caseflow Technical Support Team does not issue or manage access to Caseflow. Please do not submit a ticket
          through YourIT to the Caseflow team if you are looking for access to Caseflow or another VA product.
        </p>
        <p tabIndex={0}>
          Access is approved and granted via email through your management team and your local
          CSEM Information Security Officer (ISO). Please email your management team for access guidance.
        </p>
      </StatusMessage>
    </AppFrame>
    <Footer
      appName= "Feedback"
      feedbackUrl={props.feedbackUrl}
      buildDate={props.buildDate} />
  </div>
</BrowserRouter>;

Feedback.propTypes = {
  dropdownUrls: PropTypes.array,
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.string
};

export default Feedback;
