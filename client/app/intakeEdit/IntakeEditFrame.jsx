import React from 'react';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { BrowserRouter, Route } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_PATHS } from '../intake/constants';
import { EditAddIssuesPage } from '../intake/pages/addIssues';
import DecisionReviewEditCompletedPage from '../intake/pages/decisionReviewEditCompleted';
import Message from './pages/message';
import { css } from 'glamor';
import EditButtons from './components/EditButtons';
import PropTypes from 'prop-types';

const textAlignRightStyling = css({
  textAlign: 'right',
});

export class IntakeEditFrame extends React.PureComponent {
  displayClearedEpMessage = (details) => {
    return `Other end products associated with this ${
      details.formName
    } have already been decided,
      so issues are no longer editable. If this is a problem, please contact the Caseflow team
      via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket via YourIT.`;
  };

  displayConfirmationMessage = (details) => {
    return `${
      details.veteran.name
    }'s claim review has been successfully edited. You can close this window.`;
  };

  displayNotEditableMessage = () => {
    const { asyncJobUrl } = this.props.serverIntake;

    return (
      <React.Fragment>
        Review not yet established in VBMS. Check{' '}
        <Link href={asyncJobUrl}>the job page</Link> for details. You may try to
        edit the review again once it has been established.
      </React.Fragment>
    );
  };

  displayCanceledMessage = (details) => {
    const {
      editIssuesUrl,
      hasClearedNonratingEp,
      hasClearedRatingEp,
    } = this.props.serverIntake;

    if (hasClearedNonratingEp || hasClearedRatingEp) {
      return (
        <span>
          No changes were made to {details.veteran.name}'s (ID #
          {details.veteran.fileNumber})&nbsp;
          {details.formName}. If needed, you may{' '}
          <a href={editIssuesUrl}>correct the issues.</a>
        </span>
      );
    }

    return `No changes were made to ${details.veteran.name}'s (ID #${
      details.veteran.fileNumber
    }) ${details.formName}.
      Go to VBMS claim details and click the “Edit in Caseflow” button to return to edit.`;
  };

  displayOutcodedMessage = () => {
    return 'This appeal has been outcoded and the issues are no longer editable.';
  };

  render() {
    const { veteran, formType } = this.props.serverIntake;

    const appName = 'Intake';

    const Router = this.props.router || BrowserRouter;

    const topMessage = veteran.fileNumber ?
      `${veteran.formName} (${veteran.fileNumber})` :
      null;

    const basename = `/${formType}s/${this.props.claimId}/edit/`;

    return (
      <Router basename={basename} {...this.props.routerTestProps}>
        <div>
          <NavigationBar
            appName={appName}
            logoProps={{
              accentColor: LOGO_COLORS.INTAKE.ACCENT,
              overlapColor: LOGO_COLORS.INTAKE.OVERLAP,
            }}
            userDisplayName={this.props.userDisplayName}
            dropdownUrls={this.props.dropdownUrls}
            topMessage={topMessage}
            defaultUrl="/"
          >
            <AppFrame>
              <AppSegment filledBackground>
                <div>
                  <PageRoute
                    exact
                    path={PAGE_PATHS.BEGIN}
                    title="Edit Claim Issues | Caseflow Intake"
                    component={EditAddIssuesPage}
                  />
                  <PageRoute
                    exact
                    path={PAGE_PATHS.NOT_EDITABLE}
                    title="Edit Claim Issues | Caseflow Intake"
                    component={() => {
                      return (
                        <Message
                          title="Review not editable"
                          displayMessage={this.displayNotEditableMessage}
                        />
                      );
                    }}
                  />
                  <PageRoute
                    exact
                    path={PAGE_PATHS.CANCEL_ISSUES}
                    title="Edit Claim Issues | Caseflow Intake"
                    component={() => {
                      return (
                        <Message
                          title="Edit Canceled"
                          displayMessage={this.displayCanceledMessage}
                        />
                      );
                    }}
                  />
                  <PageRoute
                    exact
                    path={PAGE_PATHS.CONFIRMATION}
                    title="Edit Claim Issues | Caseflow Intake"
                    component={DecisionReviewEditCompletedPage}
                  />
                  <PageRoute
                    exact
                    path={PAGE_PATHS.CLEARED_EPS}
                    title="Edit Claim Issues | Caseflow Intake"
                    component={() => {
                      return (
                        <Message
                          title="Issues Not Editable"
                          displayMessage={this.displayClearedEpMessage}
                        />
                      );
                    }}
                  />
                  <PageRoute
                    exact
                    path={PAGE_PATHS.OUTCODED}
                    title="Edit Claim Issues | Caseflow Intake"
                    component={() => {
                      return (
                        <Message
                          title="Issues Not Editable"
                          displayMessage={this.displayOutcodedMessage}
                        />
                      );
                    }}
                  />
                </div>
              </AppSegment>
              <AppSegment styling={textAlignRightStyling}>
                <Route exact path={PAGE_PATHS.BEGIN} component={EditButtons} />
              </AppSegment>
            </AppFrame>
          </NavigationBar>

          <Footer
            appName={appName}
            feedbackUrl={this.props.feedbackUrl}
            buildDate={this.props.buildDate}
          />
        </div>
      </Router>
    );
  }
}

IntakeEditFrame.propTypes = {
  feedbackUrl: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
  serverIntake: PropTypes.shape({
    veteran: PropTypes.object,
    formType: PropTypes.string,
    editIssuesUrl: PropTypes.string,
    asyncJobUrl: PropTypes.string,
    hasClearedNonratingEp: PropTypes.bool,
    hasClearedRatingEp: PropTypes.bool,
  }),
  dropdownUrls: PropTypes.array,
  userDisplayName: PropTypes.string,
  claimId: PropTypes.string,
  routerTestProps: PropTypes.object,
  router: PropTypes.object,
};

export default IntakeEditFrame;
