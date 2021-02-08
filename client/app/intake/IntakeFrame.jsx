/* eslint-disable react/prop-types */
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import NavigationBar from '../components/NavigationBar';
import CaseSearchLink from '../components/CaseSearchLink';
import InboxLink from '../components/InboxLink';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { useHistory } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import CancelIntakeModal from './components/CancelIntakeModal';
import SelectFormPage, { SelectFormButton } from './pages/selectForm';
import SearchPage from './pages/search';
import ReviewPage, { ReviewButtons } from './pages/review';
import FinishPage, { FinishButtons } from './pages/finish';
import { IntakeAddIssuesPage } from './pages/addIssues';
import CompletedPage, { CompletedNextButton } from './pages/completed';
import { PAGE_PATHS } from './constants';
import { toggleCancelModal, submitCancel } from './actions/intake';
import { LOGO_COLORS } from '../constants/AppConstants';
import { IntakeLayout } from './components/IntakeLayout';
import { AddClaimantPage } from './addClaimant/AddClaimantPage';
import { AddPoaPage } from './addPOA/AddPoaPage';

export const IntakeFrame = (props) => {
  const history = useHistory();

  const appName = 'Intake';

  const topMessage = props.veteran.fileNumber ?
    `${props.veteran.formName} (${props.veteran.fileNumber})` :
    null;

  let rightNavElements = <CaseSearchLink newWindow />;

  if (props.featureToggles.inbox) {
    rightNavElements = (
      <span>
        <InboxLink youveGotMail={props.unreadMessages} />
        <CaseSearchLink newWindow />
      </span>
    );
  }

  return (
    <div>
      {props.cancelModalVisible && (
        <CancelIntakeModal
          intakeId={props.intakeId}
          closeHandler={props.toggleCancelModal}
        />
      )}
      <NavigationBar
        appName={appName}
        logoProps={{
          accentColor: LOGO_COLORS.INTAKE.ACCENT,
          overlapColor: LOGO_COLORS.INTAKE.OVERLAP,
        }}
        rightNavElement={rightNavElements}
        userDisplayName={props.userDisplayName}
        dropdownUrls={props.dropdownUrls}
        topMessage={topMessage}
        defaultUrl="/"
      >
        <AppFrame>
          <PageRoute
            exact
            path={PAGE_PATHS.BEGIN}
            title="Select Form | Caseflow Intake"
          >
            <IntakeLayout
              buttons={<SelectFormButton {...props} history={history} />}
            >
              <SelectFormPage {...props} />
            </IntakeLayout>
          </PageRoute>

          <PageRoute
            exact
            path={PAGE_PATHS.SEARCH}
            title="Search | Caseflow Intake"
          >
            <IntakeLayout>
              <SearchPage />
            </IntakeLayout>
          </PageRoute>

          <PageRoute
            exact
            path={PAGE_PATHS.REVIEW}
            title="Review Request | Caseflow Intake"
          >
            <IntakeLayout buttons={<ReviewButtons history={history} />}>
              <ReviewPage featureToggles={props.featureToggles} />
            </IntakeLayout>
          </PageRoute>

          <PageRoute
            exact
            path={PAGE_PATHS.ADD_CLAIMANT}
            title="Add Claimant | Caseflow Intake"
          >
            <AddClaimantPage />
          </PageRoute>

          <PageRoute
            exact
            path={PAGE_PATHS.ADD_POWER_OF_ATTORNEY}
            title="Add Power of Attorney | Caseflow Intake"
          >
            <AddPoaPage />
          </PageRoute>

          <PageRoute
            exact
            path={PAGE_PATHS.ADD_ISSUES}
            title="Add / Remove Issues | Caseflow Intake"
          >
            <IntakeLayout buttons={<FinishButtons history={history} />}>
              <IntakeAddIssuesPage featureToggles={props.featureToggles} />
            </IntakeLayout>
          </PageRoute>

          <PageRoute
            exact
            path={PAGE_PATHS.FINISH}
            title="Finish Processing | Caseflow Intake"
          >
            <IntakeLayout buttons={<FinishButtons history={history} />}>
              <FinishPage history={history} />
            </IntakeLayout>
          </PageRoute>

          <PageRoute
            exact
            path={PAGE_PATHS.COMPLETED}
            title="Confirmation | Caseflow Intake"
          >
            <IntakeLayout buttons={<CompletedNextButton history={history} />}>
              <CompletedPage history={history} />
            </IntakeLayout>
          </PageRoute>
        </AppFrame>
      </NavigationBar>
      <Footer
        appName={appName}
        feedbackUrl={props.feedbackUrl}
        buildDate={props.buildDate}
      />
    </div>
  );
};

export default connect(
  ({ intake }) => ({
    intakeId: intake.id,
    unreadMessages: intake.unreadMessages,
    veteran: intake.veteran,
    cancelModalVisible: intake.cancelModalVisible,
    cancelIntakeRequestStatus: intake.requestStatus.cancel,
  }),
  (dispatch) =>
    bindActionCreators(
      {
        toggleCancelModal,
        submitCancel,
      },
      dispatch
    )
)(IntakeFrame);
