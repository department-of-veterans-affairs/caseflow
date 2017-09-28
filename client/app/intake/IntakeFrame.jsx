import React from 'react';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '../components/AppSegment';
import ProgressBar from '../components/ProgressBar';
import PrimaryAppContent from '../components/PrimaryAppContent';
import BeginPage from './pages/begin';
import ReviewPage, { ReviewNextButton } from './pages/review';
import FinishPage, { FinishNextButton } from './pages/finish';
import CompletedPage, { CompletedNextButton } from './pages/completed';

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
              <PageRoute
                exact
                path="/finish"
                title="Finish | Caseflow Intake"
                component={FinishPage} />
              <PageRoute
                exact
                path="/completed"
                title="Completed | Caseflow Intake"
                component={CompletedPage} />
            </PrimaryAppContent>
            <AppSegment className="cf-workflow-button-wrapper">
              <Route
                exact
                path="/review-request"
                component={ReviewNextButton} />
              <Route
                exact
                path="/finish"
                component={FinishNextButton} />
              <Route
                exact
                path="/completed"
                component={CompletedNextButton} />
            </AppSegment>
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
