import React, { useState, createContext } from 'react';
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
import SplitAppealView from '../intake/pages/SplitAppealView';
import DecisionReviewEditCompletedPage from '../intake/pages/decisionReviewEditCompleted';
import Message from './pages/message';
import { css } from 'glamor';
import EditButtons from './components/EditButtons';
import CreateButtons from './components/CreateButtons';
import PropTypes from 'prop-types';
import SplitAppealProgressBar from '../intake/components/SplitAppealProgressBar';
import SplitButtons from './components/SplitButtons';
import IntakeAppealContext from './components/IntakeAppealContext';
import ReviewAppealView from '../intake/pages/ReviewAppealView';

const textAlignRightStyling = css({
  textAlign: 'right',
});

export const StateContext = createContext({});

export const RequestIssueContext = createContext();

export const Provider = ({ children }) => {
  const [reason, setReason] = useState(null);
  const [otherReason, setOtherReason] = useState('');
  const [selectedIssues, setSelectedIssues] = useState({});

  return (
    <StateContext.Provider value={{
      reason,
      setReason,
      otherReason,
      setOtherReason,
      selectedIssues,
      setSelectedIssues
    }}>
      {children}
    </StateContext.Provider>
  );
};

Provider.propTypes = {
  children: PropTypes.node
};

export const IntakeEditFrame = (props) => {

  const displayClearedEpMessage = (details) => {
    return `Other end products associated with this ${
      details.formName
    } have already been decided,
      so issues are no longer editable. If this is a problem, please contact the Caseflow team
      via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket via YourIT.`;
  };

  const displayNotEditableMessage = () => {
    const asyncJobUrl = props.serverIntake.asyncJobUrl;

    return (
      <React.Fragment>
        Review not yet established in VBMS. Check{' '}
        <Link href={asyncJobUrl}>the job page</Link> for details. You may try to
        edit the review again once it has been established.
      </React.Fragment>
    );
  };

  const displayCanceledMessage = (details) => {
    const editIssuesUrl = props.serverIntake.editIssuesUrl;
    const hasClearedNonratingEp = props.serverIntake.hasClearedNonratingEp;
    const hasClearedRatingEp = props.serverIntake.hasClearedRatingEp;

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

  const displayOutcodedMessage = () => {
    return 'This appeal has been outcoded and the issues are no longer editable.';
  };

  const displayDecisionDateMessage = () => {
    return 'One or more request issues lack a decision date. Please contact the Caseflow team via the VA Enterprise Service Desk at 855-673-4357 or create a YourIT ticket to correct these issues.'; // eslint-disable-line max-len
  };

  const { veteran, formType } = props.serverIntake;

  const appName = 'Intake';

  const Router = props.router || BrowserRouter;

  const topMessage = veteran.fileNumber ?
      `${veteran.formName} (${veteran.fileNumber})` :
    null;

  const basename = `/${formType}s/${props.claimId}/edit/`;

  return (
    <Router basename={basename} {...props.routerTestProps}>
      <div>
        <NavigationBar
          appName={appName}
          logoProps={{
            accentColor: LOGO_COLORS.INTAKE.ACCENT,
            overlapColor: LOGO_COLORS.INTAKE.OVERLAP,
          }}
          userDisplayName={props.userDisplayName}
          dropdownUrls={props.dropdownUrls}
          topMessage={topMessage}
          defaultUrl="/"
        >
          <AppFrame>
            <Route exact path={PAGE_PATHS.CREATE_SPLIT} component={SplitAppealProgressBar} />
            <Route exact path={PAGE_PATHS.REVIEW_SPLIT} component={SplitAppealProgressBar} />
            <Provider>
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
                          displayMessage={displayNotEditableMessage}
                        />
                      );
                    }}
                  />
                  <PageRoute
                    exact
                    path={PAGE_PATHS.REQUEST_ISSUE_MISSING_DECISION_DATE}
                    title="Edit Claim Issues | Caseflow Intake"
                    component={() => {
                      return (
                        <Message
                          title="Review not editable"
                          displayMessage={displayDecisionDateMessage}
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
                          displayMessage={displayCanceledMessage}
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
                          displayMessage={displayClearedEpMessage}
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
                          displayMessage={displayOutcodedMessage}
                        />
                      );
                    }}
                  />

                  <PageRoute
                    exact
                    path={PAGE_PATHS.CREATE_SPLIT}
                    title="Split Appeal | Caseflow Intake"
                    component={() => {
                      return (
                        <SplitAppealView {...props} />
                      );
                    }}
                  />

                  <PageRoute
                    exact
                    path={PAGE_PATHS.REVIEW_SPLIT}
                    title="Split Appeal | Caseflow Intake"
                    component={() => {
                      return (
                        <ReviewAppealView {...props} />
                      );
                    }}
                  />
                </div>
              </AppSegment>
              <AppSegment styling={textAlignRightStyling}>
                <Route exact path={PAGE_PATHS.BEGIN} component={EditButtons} />
                <RequestIssueContext.Provider value={props.serverIntake.requestIssues.length}>
                  <Route exact path={PAGE_PATHS.CREATE_SPLIT} component={SplitButtons} />
                </RequestIssueContext.Provider>
                <IntakeAppealContext.Provider value={[props.appeal, props.user]}>
                  <Route exact path={PAGE_PATHS.REVIEW_SPLIT} component={CreateButtons} />
                </IntakeAppealContext.Provider>
              </AppSegment>
            </Provider>
          </AppFrame>
        </NavigationBar>

        <Footer
          appName={appName}
          feedbackUrl={props.feedbackUrl}
          buildDate={props.buildDate}
        />
      </div>
    </Router>
  );
};

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
    requestIssues: PropTypes.array
  }),
  dropdownUrls: PropTypes.array,
  userDisplayName: PropTypes.string,
  appeal: PropTypes.object,
  claimId: PropTypes.string,
  user: PropTypes.string,
  isLegacy: PropTypes.bool,
  routerTestProps: PropTypes.object,
  router: PropTypes.object
};

export default IntakeEditFrame;
