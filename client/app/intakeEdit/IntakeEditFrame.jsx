import React from 'react';
import { connect } from 'react-redux';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_PATHS } from './constants';
import { EditAddIssuesPage } from '../intake/pages/addIssues';
import CancelPage from './pages/cancelled';
import SelectIssuesPage, { SelectIssuesButtons } from './pages/selectIssues';
import { css } from 'glamor';
import CancelEditButton from './components/CancelEditButton';

const textAlignRightStyling = css({
  textAlign: 'right'
});

export default class IntakeEditFrame extends React.PureComponent {
  render() {
    const {
      claimId,
      veteranFileNumber,
      veteranFormName,
      formType
    } = this.props.serverIntake;

    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = veteranFileNumber ?
      `${veteranFormName} (${veteranFileNumber})` : null;

    const basename = `/${formType}s/${claimId}/edit/`;

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
                  component={EditAddIssuesPage} />
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
                component={CancelEditButton}
              />
              <Route
                exact
                path={PAGE_PATHS.SELECT_ISSUES}
                component={SelectIssuesButtons}
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
