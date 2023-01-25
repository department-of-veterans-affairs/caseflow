import React from 'react';
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
import VhaHelp from './components/VhaHelp';

class Help extends React.PureComponent {

  render() {

    return <BrowserRouter>
      <div>
        <NavigationBar
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
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
          </div>
        </AppFrame>
        <Footer
          appName="Help"
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate} />
      </div>
    </BrowserRouter>;
  }
}
export default Help;
