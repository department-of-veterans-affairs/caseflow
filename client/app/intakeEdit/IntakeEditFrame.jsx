import React from 'react';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_PATHS } from '../intake/constants';
import { EditAddIssuesPage } from '../intake/pages/addIssues';
import CancelPage from './pages/canceled';
import ConfirmationPage from './pages/confirmation';
import ClearedEndProductsPage from  './pages/clearedEndProducts';
import StatusMessage from '../components/StatusMessage';
import { css } from 'glamor';
import EditButtons from './components/EditButtons';

const textAlignRightStyling = css({
  textAlign: 'right'
});

export default class IntakeEditFrame extends React.PureComponent {
  displayClearedEpMessage(details) = {
    return `Other end products associated with this ${details.formName} have already been decided, 
        so issues are no longer editable. If this is a problem, please contact Caseflow support.`
  }

  render() {
    const {
      veteran,
      formType
    } = this.props.serverIntake;

    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = veteran.fileNumber ?
      `${veteran.formName} (${veteran.fileNumber})` : null;

    const basename = `/${formType}s/${this.props.claimId}/edit/`;

    const dtaMessage = `Because this claim was created by Caseflow to resolve DTA errors,
    its issues may not be edited. You can close this window and return to VBMS.`;

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
                <PageRoute
                  exact
                  path={PAGE_PATHS.CONFIRMATION}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={ConfirmationPage} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.DTA_CLAIM}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={() => {
                    return <StatusMessage title="Issues Not Editable"
                      leadMessageList={[dtaMessage]} />;
                  }} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.CLEARED_EPS}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={() => {
                    return <Message title="Issues Not Editable" displayMessage={this.displayClearedEpMessage}
                  }} />
              </div>
            </AppSegment>
            <AppSegment styling={textAlignRightStyling}>
              <Route
                exact
                path={PAGE_PATHS.BEGIN}
                component={EditButtons}
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
