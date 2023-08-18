import React, { useEffect } from 'react';
import { BrowserRouter } from 'react-router-dom';
import AppFrame from '../components/AppFrame';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import HelpRootView from './HelpRootView';
import CertificationHelp from './components/CertificationHelp';
import HearingsHelp from './components/HearingsHelp';
import ReaderHelp from './components/ReaderHelp';
import HearingsTest from './components/HearingsTest';
import DispatchHelp from './components/DispatchHelp';
import IntakeHelp from './components/IntakeHelp';
import QueueHelp from './components/QueueHelp';
import VhaHelp from './components/VhaHelp';
import ReduxBase from '../components/ReduxBase';
import helpReducers, {
  setFeatureToggles,
  setOrganizationMembershipRequests,
  setUserLoggedIn,
  setUserOrganizations } from './helpApiSlice';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

// Apollo Client and GraphQL
import { ApolloClient, InMemoryCache, ApolloProvider } from '@apollo/client';

const apolloClient = new ApolloClient({
  uri: 'http://localhost:3000/graphql',
  cache: new InMemoryCache()
});

const Help = (props) => {

  return <ApolloProvider client={apolloClient}>
    <ReduxBase
      reducer={helpReducers}
    >
      <BrowserRouter>
        <HelpApp {...props} />
      </BrowserRouter>
    </ReduxBase>
  </ApolloProvider>;

};

const HelpApp = (props) => {

  const dispatch = useDispatch();

  // Initialize the redux store with props from the server
  useEffect(() => {
    dispatch(setUserOrganizations(props.userOrganizations));
  }, [dispatch, props.userOrganizations]);

  useEffect(() => {
    dispatch(setFeatureToggles(props.featureToggles));
  }, [dispatch, props.featureToggles]);

  useEffect(() => {
    dispatch(setOrganizationMembershipRequests(props.organizationMembershipRequests));
  }, [dispatch, props.organizationMembershipRequests]);

  useEffect(() => {
    dispatch(setUserLoggedIn(props.userLoggedIn));
  }, [dispatch, props.userLoggedIn]);

  return (
    <div>
      <NavigationBar
        userDisplayName={props.userDisplayName}
        dropdownUrls={props.dropdownUrls}
        appName="Help"
        defaultUrl="/"
        logoProps={{
          accentColor: COLORS.GREY_DARK,
          overlapColor: COLORS.GREY_DARK
        }} />
      <AppFrame>
        <div className="cf-app-width cf-app-segment cf-app-segment--alt">
          <PageRoute exact
            path="/help"
            title="Caseflow Help"
            component={HelpRootView} />
          <PageRoute exact
            path="/"
            title="Caseflow Help"
            component={HelpRootView} />
          <PageRoute exact
            path="/certification/help"
            title="Certification Help"
            component={CertificationHelp} />
          <PageRoute exact
            path="/reader/help"
            title="Reader Help"
            component={ReaderHelp} />
          <PageRoute exact
            path="/hearing_prep/help"
            title="Hearings Help"
            component={HearingsHelp} />
          <PageRoute exact
            path="/dispatch/help"
            title="Dispatch Help"
            component={DispatchHelp} />
          <PageRoute exact
            path="/intake/help"
            title="Intake Help"
            component={IntakeHelp} />
          <PageRoute exact
            path="/queue/help"
            title="Queue Help"
            component={QueueHelp} />
          <PageRoute exact
            path="/vha/help"
            title="Vha Help"
            component={VhaHelp} />
          <PageRoute exact
            path="/hearings_query/test"
            title="Hearings Query Test"
            component={HearingsTest} />
        </div>
      </AppFrame>
      <Footer
        appName="Help"
        feedbackUrl={props.feedbackUrl}
        buildDate={props.buildDate} />
    </div>
  );
};

HelpApp.propTypes = {
  dropdownUrls: PropTypes.object,
  userDisplayName: PropTypes.string,
  buildDate: PropTypes.string,
  feedbackUrl: PropTypes.string.isRequired,
  userOrganizations: PropTypes.array,
  organizationMembershipRequests: PropTypes.array,
  featureToggles: PropTypes.object,
  userLoggedIn: PropTypes.bool,
};

export default Help;
