import React from 'react';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_PATHS } from './constants';
import LandingPage from './pages/landing';
import SelectIssuesPage from './pages/selectIssues';

export default class IntakeEditFrame extends React.PureComponent {
  render() {
    const {
      review,
      formType
    } = this.props;

    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = review.veteranFileNumber ?
      `${review.veteranFormName} (${review.veteranFileNumber})` : null;

    const basename = `/${formType}s/${review.claimId}/edit/`;

    return <Router basename={basename} {...this.props.routerTestProps}>
      <div>
        <NavigationBar
          appName={appName}
          logoProps={{
            accentColor: LOGO_COLORS.INTAKE.ACCENT,
            overlapColor: LOGO_COLORS.INTAKE.OVERLAP
          }}
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          topMessage={topMessage}
          defaultUrl="/">
          <AppFrame>
            <AppSegment filledBackground>
              <div>
                <PageRoute
                  exact
                  path={PAGE_PATHS.BEGIN}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={LandingPage} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.SELECT_ISSUES}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={SelectIssuesPage} />
              </div>
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
