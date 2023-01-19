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
import DispatchHelp from './components/DispatchHelp';
import IntakeHelp from './components/IntakeHelp';
import QueueHelp from './components/QueueHelp';
import ReduxBase from '../components/ReduxBase';
import helpReducer, { initialState } from './helpReducers';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import { setOrganizations } from './helpActions';

class Help extends React.PureComponent {

  render() {
    console.log('help props and state');
    console.log(this.props);
    console.log(this.state);

    return <ReduxBase
      reducer={helpReducer}
      initialState={{ help: { ...initialState } }}
    >
      <BrowserRouter>
        <HelpApp {...this.props} />
      </BrowserRouter>
    </ReduxBase>;
  }
}

const HelpApp = (props) => {

  const dispatch = useDispatch();

  console.log(props);

  useEffect(() => {
    dispatch(setOrganizations(props.userOrganizations));
  }, [dispatch, props.userOrganizations]);

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
        </div>
      </AppFrame>
      <Footer
        appName="Help"
        feedbackUrl={props.feedbackUrl}
        buildDate={props.buildDate} />
    </div>
  );
};

Help.propTypes = {

};

HelpApp.propTypes = {
  dropdownUrls: PropTypes.object,
  userDisplayName: PropTypes.string,
  buildDate: PropTypes.string,
  feedbackUrl: PropTypes.string.isRequired,
};

export default Help;
