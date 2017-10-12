import React from 'react';
import { connect } from 'react-redux';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '../components/AppSegment';
import IntakeProgressBar from './components/IntakeProgressBar';
import PrimaryAppContent from '../components/PrimaryAppContent';
import BeginPage from './pages/begin';
import ReviewPage, { ReviewNextButton } from './pages/review';
import FinishPage, { FinishNextButton } from './pages/finish';
import CompletedPage, { CompletedNextButton } from './pages/completed';
import { PAGE_PATHS } from './constants';

class IntakeFrame extends React.PureComponent {
  render() {
    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = this.props.veteran ?
    `${this.props.veteran.formName} (${this.props.veteran.fileNumber})` : null;

    return <Router basename="/intake" {...this.props.routerTestProps}>
      <div>
        <NavigationBar
          appName={appName}
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          topMessage={topMessage}
          defaultUrl="/">
          <AppFrame>
            <IntakeProgressBar />
            <PrimaryAppContent>
              <PageRoute
                exact
                path={PAGE_PATHS.BEGIN}
                title="Begin Intake | Caseflow Intake"
                component={BeginPage} />
              <PageRoute
                exact
                path={PAGE_PATHS.REVIEW}
                title="Review Request | Caseflow Intake"
                component={ReviewPage} />
              <PageRoute
                exact
                path={PAGE_PATHS.FINISH}
                title="Finish | Caseflow Intake"
                component={FinishPage} />
              <PageRoute
                exact
                path={PAGE_PATHS.COMPLETED}
                title="Completed | Caseflow Intake"
                component={CompletedPage} />
            </PrimaryAppContent>
            <AppSegment className="cf-workflow-button-wrapper">
              <Route
                exact
                path={PAGE_PATHS.REVIEW}
                component={ReviewNextButton} />
              <Route
                exact
                path={PAGE_PATHS.FINISH}
                component={FinishNextButton} />
              <Route
                exact
                path={PAGE_PATHS.COMPLETED}
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

export default connect(
  ({ veteran, requestStatus }) => ({
    veteran,
    fileNumberSearchRequestStatus: requestStatus.fileNumberSearch
  })
)(IntakeFrame);
