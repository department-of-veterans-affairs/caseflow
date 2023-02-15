import React from 'react';
import VhaMembershipRequestForm from './VhaMembershipRequestForm';
import Alert from '../../components/Alert';
import { VHA_FORM_SUBMIT_SUCCESS_MESSAGE, VHA_FORM_SUBMIT_SUCCESS_TITLE } from '../constants';

const VhaHelp = () => {

  const Header = () => {
    return <div>
      <h1 id="#top"> Welcome to the VHA Help page! </h1>
      <p>Here you will find
        <a href="#training-videos"> Training Videos</a>
        and
        <a href="#faq"> Frequently Asked Questions (FAQs)</a>
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

  const SuccessBanner = () => {
    // Not sure where to grab this from. Either message props or FormRedux
    const vhaFormSuccess = false;

    return vhaFormSuccess && <div style={{ marginBottom: '3rem' }}>
      <Alert
        type="success"
        title={VHA_FORM_SUBMIT_SUCCESS_TITLE}
        message={VHA_FORM_SUBMIT_SUCCESS_MESSAGE}
      />
    </div>;
  };

  return <div className="cf-help-content">
    <SuccessBanner />
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
