import React from 'react';
import VhaMembershipRequestForm from './VhaMembershipRequestForm';
import Alert from '../../components/Alert';
import { VHA_FORM_SUBMIT_SUCCESS_TITLE } from '../constants';
import { useSelector } from 'react-redux';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const VhaHelp = () => {

  // Success message selector for displaying the banner after object creation
  const successMessage = useSelector(
    (state) => state.help.messages.success
  );

  const errorMessage = useSelector(
    (state) => state.help.messages.error
  );

  const userIsLoggedIn = useSelector(
    (state) => state.help.userLoggedIn
  );

  const BackToHelpLink = () => {
    return <p><Link href="/help">Go Back</Link></p>;
  };

  const Header = () => {
    return <div>
      <h1 id="#top"> Welcome to the VHA Help page! </h1>
      <p>Here you will find
        <a href="#training-videos"> Training Videos </a>
        and
        <a href="#faq"> Frequently Asked Questions (FAQs) </a>
       for VHA, as well as links to the Training Guide and the Quick Reference Guide </p>
    </div>;
  };

  const TrainingVideos = () => {
    return <div>
      <h1 id="training-videos"> Training Videos</h1>
      <p> Training video for business lines </p>
    </div>;
  };

  const FrequentlyAskedQuestions = () => {
    return <div>
      <h1 id="faq"> Frequently Asked Questions </h1>
    </div>;
  };

  const HelpDivider = () => {
    return <div className="cf-help-divider"></div>;
  };

  const SuccesssBanner = () => {
    return successMessage ? <div style={{ marginBottom: '3rem' }}>
      <Alert
        type="success"
        title={VHA_FORM_SUBMIT_SUCCESS_TITLE}
        message={successMessage}
      />
    </div> : null;
  };

  const ErrorBanner = () => {
    return errorMessage ? <div style={{ marginBottom: '3rem' }}>
      <Alert
        type="error"
        title="An error occurred with processing your request. Please try again later."
        message={errorMessage}
      />
    </div> : null;
  };

  return <div className="cf-help-content">
    <SuccesssBanner />
    <ErrorBanner />
    <BackToHelpLink />
    <Header />
    <HelpDivider />
    <TrainingVideos />
    <HelpDivider />
    <FrequentlyAskedQuestions />
    <HelpDivider />
    { userIsLoggedIn && <VhaMembershipRequestForm /> }
  </div>;
};

export default VhaHelp;
