import React, { useEffect } from 'react';
import VhaMembershipRequestForm from './VhaMembershipRequestForm';
import Alert from '../../components/Alert';
import { VHA_FORM_SUBMIT_SUCCESS_TITLE } from '../constants';
import { useDispatch, useSelector } from 'react-redux';
import { resetSuccessMessage, resetErrorMessage } from '../helpApiSlice';

const VhaHelp = () => {

  const dispatch = useDispatch();

  // Success message selector for displaying the banner after object creation
  // TODO: look into createSelector for some of these and see if it is worth it.
  const successMessage = useSelector(
    (state) => state.help.messages.success
  );

  const errorMessage = useSelector(
    (state) => state.help.messages.error
  );

  // TODO: While, I think this should be done. This makes testing difficult
  // useEffect(() => {
  //   // Clear the form success message on first component render
  //   // dispatch(resetFormSuccessMessage());
  //   // dispatch(resetSuccessMessage());
  //   // TODO: might need to do this too?
  //   // dispatch(resetErrorMessage());
  // }, [dispatch]);

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
        title="Something went wrong"
        message={errorMessage}
      />
    </div> : null;
  };

  return <div className="cf-help-content">
    <SuccesssBanner />
    <ErrorBanner />
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
