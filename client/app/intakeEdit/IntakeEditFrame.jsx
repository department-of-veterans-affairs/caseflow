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
import DecisionReviewEditCompletedPage from '../intake/pages/decisionReviewEditCompleted';
import Message from './pages/message';
import { css } from 'glamor';
import EditButtons from './components/EditButtons';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';


const textAlignRightStyling = css({
  textAlign: 'right'
});

export default class IntakeEditFrame extends React.PureComponent {
  displayClearedEpMessage = (details) => {
    return `Other end products associated with this ${details.formName} have already been decided,
      so issues are no longer editable. If this is a problem, please contact the Caseflow team
      via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket via YourIT.`;
  }

  displayDtaMessage = () => {
    return `Because this claim was created by Caseflow to resolve DTA errors,
      its issues may not be edited. You can close this window and return to VBMS.`;
  }

  displayConfirmationMessage = (details) => {
    return `${details.veteran.name}'s claim review has been successfully edited. You can close this window.`;
  }

  displayCanceledMessage = (details) => {
    return `No changes were made to ${details.veteran.name}'s (ID #${details.veteran.fileNumber}) ${details.formName}.
      Go to VBMS claim details and click the “Edit in Caseflow” button to return to edit.`;
  }

   displayCorrectionMessage = (details) => {
    return <span>No changes were made to {details.veteran.name}'s (ID #{details.veteran.fileNumber}) {details.formName}.
     If needed, you may <a href={this.props.serverIntake.editIssuesUrl} target="_blank">correct the issues.</a></span>;
  }

  displayOutcodedMessage = () => {
    return 'This appeal has been outcoded and the issues are no longer editable.';
  }

  render() {
    const {
      veteran,
      formType,
      editIssuesUrl
    } = this.props.serverIntake;

    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = veteran.fileNumber ?
      `${veteran.formName} (${veteran.fileNumber})` : null;

    const basename = `/${formType}s/${this.props.claimId}/edit/`;

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
                  component={() => {
                    return <Message title="Edit Canceled" displayMessage={this.displayCorrectionMessage} />;
                  }} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.CONFIRMATION}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={DecisionReviewEditCompletedPage} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.DTA_CLAIM}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={() => {
                    return <Message title="Issues Not Editable" displayMessage={this.displayDtaMessage} />;
                  }} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.CLEARED_EPS}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={() => {
                    return <Message title="Issues Not Editable" displayMessage={this.displayClearedEpMessage} />;
                  }} />
                <PageRoute
                  exact
                  path={PAGE_PATHS.OUTCODED}
                  title="Edit Claim Issues | Caseflow Intake"
                  component={() => {
                    return <Message title="Issues Not Editable" displayMessage={this.displayOutcodedMessage} />;
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
