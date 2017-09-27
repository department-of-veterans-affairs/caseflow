import React from 'react';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import ProgressBar from '../components/ProgressBar';
import PrimaryAppContent from '../components/PrimaryAppContent';
import BeginPage from './pages/begin';
import ReviewPage from './pages/review';

export default class IntakeFrame extends React.PureComponent {
  render() {
    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const progressBarSections = [
      { title: '1. Begin Intake' },
      { title: '2. Review Request' },
      { title: '3. Finish Processing' },
      { title: '4. Confirmation' }
    ];

    return <Router basename="/intake" {...this.props.routerTestProps}>
      <div>
        <NavigationBar
          appName={appName}
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          defaultUrl="/"
        >
          <AppFrame>
            <ProgressBar sections={progressBarSections} />
            <PrimaryAppContent>
              <PageRoute
                exact
                path="/"
                title="Begin Intake | Caseflow Intake"
                component={BeginPage} />
              <PageRoute
                exact
                path="/review-request"
                title="Review Request | Caseflow Intake"
                component={ReviewPage} />
              </PrimaryAppContent>
          </AppFrame>
        </NavigationBar>
        <Footer
          appName={appName}
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate}
        />
      </div>
    </Router>;
  }
}
