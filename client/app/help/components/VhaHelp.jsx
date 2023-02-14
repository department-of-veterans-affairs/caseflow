import React from 'react';
import VhaMembershipRequestForm from './VhaMembershipRequestForm';
import Alert from '../../components/Alert';
import { VHA_FORM_SUBMIT_SUCCESS_MESSAGE, VHA_FORM_SUBMIT_SUCCESS_TITLE } from '../constants';
import { useSelector } from 'react-redux';

const VhaHelp = () => {

  // Success message selector for displaying the banner after object creation
  // TODO: look into createSelector for some of these and see if it is worth it.
  const successMessage = useSelector(
    (state) => state.help.messages.success
  );

  const Header = () => {
  /* eslint-disable max-len */
    return <div>
      <h1 id="#top"> Welcome to the VHA Help page! </h1>
      <p>Here you will find <a href="#training-videos"> Training Videos</a> and <a href="#faq"> Frequently Asked Questions (FAQs)</a> for Intake, as well as links to the Training Guide and the Quick Reference Guide </p>
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
    // TODO: Not sure where to grab this from. Either message props or FormRedux
    // const vhaFormSuccess = false;

    // TODO: This message needs to be built on the server and passed up I think.
    return successMessage && <div style={{ marginBottom: '3rem' }}>
      <Alert
        type="success"
        title={VHA_FORM_SUBMIT_SUCCESS_TITLE}
        message={successMessage}
      />
    </div>;
  };

  return <div className="cf-help-content">
    <SuccesssBanner />
    <Header />
    <HelpDivider />
    <TrainingVideos />
    <HelpDivider />
    <FrequentlyAskedQuestions />
    <HelpDivider />
    <VhaMembershipRequestForm />
  </div>;
};

export default VhaHelp;
