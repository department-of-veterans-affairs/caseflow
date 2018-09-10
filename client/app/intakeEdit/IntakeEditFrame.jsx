import React from 'react';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_PATHS } from './constants';
import LandingPage from './pages/landing';
import CancelPage from './pages/cancelled';
import SelectIssuesPage from './pages/selectIssues';
import { css } from 'glamor';
import CancelEdit from './components/CancelEdit';
import CancelOrSave from './components/CancelOrSave';

const textAlignRightStyling = css({
  textAlign: 'right'
});

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

    console.log("rendering intake edit frame", this.props, basename)
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
                <PageRoute
                  exact
                  path={PAGE_PATHS.CANCEL_ISSUES}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={CancelPage} />
              </div>
            </AppSegment>
            <AppSegment styling={textAlignRightStyling}>
              <Route
                exact
                path={PAGE_PATHS.BEGIN}
                component={CancelEdit}
              />
              <Route
                exact
                path={PAGE_PATHS.SELECT_ISSUES}
                component={CancelOrSave}
              />
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
