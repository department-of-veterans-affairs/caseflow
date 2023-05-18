/* eslint-disable max-lines */
import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React, { useEffect, useMemo } from 'react';
import _ from 'lodash';

import { APPELLANT_TYPES, CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS, ICON_SIZES } from '../constants/AppConstants';
import {
  appealWithDetailSelector,
  getAllTasksForAppeal,
  openScheduleHearingTasksForAppeal,
  allHearingTasksForAppeal,
  scheduleHearingTasksForAppeal
} from './selectors';
import {
  stopPollingHearing,
  transitionAlert,
  clearAlerts,
} from '../components/common/actions';
import { getQueryParams } from '../util/QueryParamsUtil';
import { parentTasks } from './utils';
import { needsPulacCerulloAlert } from './pulacCerullo';
import {
  resetErrorMessages,
  resetSuccessMessages,
  setHearingDay,
} from './uiReducer/uiActions';
import Alert from '../components/Alert';
import AppellantDetail from './AppellantDetail';
import COPY, { CASE_DETAILS_POA_SUBSTITUTE } from 'app/../COPY';
import CaseDetailsIssueList from './components/CaseDetailsIssueList';
import CaseHearingsDetail from './CaseHearingsDetail';
import { CaseTimeline } from './CaseTimeline';
import CaseTitle from './CaseTitle';
import CaseTitleDetails from './CaseTitleDetails';
import CavcDetail from './caseDetails/CavcDetail';
import CaseDetailsPostDispatchActions from './CaseDetailsPostDispatchActions';
import PowerOfAttorneyDetail from './PowerOfAttorneyDetail';
import StickyNavContentArea from './StickyNavContentArea';
import TaskSnapshot from './TaskSnapshot';
import UserAlerts from '../components/UserAlerts';
import VeteranCasesView from './VeteranCasesView';
import VeteranDetail from './VeteranDetail';
import { startPolling } from '../hearings/utils';
import FnodBanner from './components/FnodBanner';
import {
  appealHasSubstitution,
  isAppealDispatched,
  supportsSubstitutionPostDispatch,
  supportsSubstitutionPreDispatch,
} from './substituteAppellant/caseDetails/utils';
import { VsoVisibilityAlert } from './caseDetails/VsoVisibilityAlert';
import { shouldShowVsoVisibilityAlert } from './caseDetails/utils';
import { useHistory } from 'react-router';
import Button from '../components/Button';
import { ExternalLinkIcon } from '../components/icons/ExternalLinkIcon';

// TODO: Pull this horizontal rule styling out somewhere.

const ICON_POSITION_FIX = css({ position: 'relative', top: 3 });

const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '3rem',
  marginBottom: '3rem',
});

const anchorEditLinkStyling = css({
  fontSize: '1.5rem',
  fontWeight: 'normal',
  margin: '5px',
});

const alertPaddingStyle = css({
  marginTop: '2rem',
});

const sectionGap = css({ marginBottom: '3rem' });

const editAppellantInformationLinkStyling = css({
  fontSize: '2rem',
  fontWeight: 'normal',
  margin: '5px',
});

const topAlertStyles = css({ marginBottom: '2.4rem' });

export const CaseDetailsView = (props) => {
  const { push } = useHistory();
  const { appealId, featureToggles, canViewCavcDashboards } = props;
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const updatePOALink =
    appeal.hasPOA ? COPY.EDIT_APPELLANT_INFORMATION_LINK : COPY.UP_DATE_POA_LINK;

  const tasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );
  const canEditCavcRemands = useSelector(
    (state) => state.ui.canEditCavcRemands
  );
  const userIsCobAdmin = useSelector(
    (state) => state.ui.userIsCobAdmin
  );
  const userIsVsoEmployee = useSelector(
    (state) => state.ui.userIsVsoEmployee
  );
  const success = useSelector((state) => state.ui.messages.success);
  const error = useSelector((state) => state.ui.messages.error);
  const veteranCaseListIsVisible = useSelector(
    (state) => state.ui.veteranCaseListIsVisible
  );
  const currentUserIsOnCavcLitSupport = useSelector((state) =>
    state.ui.organizations.some(
      (organization) => organization.name === 'CAVC Litigation Support'
    )
  );
  const currentUserOnClerkOfTheBoard = useSelector((state) =>
    state.ui.organizations.some((organization) =>
      ['Clerk of the Board'].includes(organization.name)
    )
  );

  const modalIsOpen = window.location.pathname.includes('modal');

  const resetState = () => {
    props.resetErrorMessages();
    props.clearAlerts();
  };

  const pollHearing = () =>
    startPolling(
      { externalId: props.scheduledHearingId },
      {
        setShouldStartPolling: props.stopPollingHearing,
        resetState,
        props,
      }
    );

  useEffect(() => {
    window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);

    // Prevent error messages from being reset if a modal is being displayed. This allows
    // the modal to show error messages without them being cleared by the CaseDetailsView.
    if (!modalIsOpen && !props.userCanScheduleVirtualHearings) {
      resetState();
    }

    const { hearingDate, regionalOffice } = getQueryParams(
      window.location.search
    );

    if (hearingDate && regionalOffice) {
      props.setHearingDay({
        hearingDate,
        regionalOffice,
      });
    }
  }, []);

  const doPulacCerulloReminder = useMemo(
    () => needsPulacCerulloAlert(appeal, tasks),
    [appeal, tasks]
  );

  const appealIsDispatched = isAppealDispatched(appeal);

  const appealHasRemandWithDashboard = useSelector((state) =>
    state.queue.appeals[appealId].cavcRemandsWithDashboard > 0
  );

  const editAppellantInformation = (
    [APPELLANT_TYPES.OTHER_CLAIMANT, APPELLANT_TYPES.HEALTHCARE_PROVIDER_CLAIMANT].includes(
      appeal.appellantType
    ) && props.featureToggles.edit_unrecognized_appellant
  );

  const editPOAInformation =
    props.userCanEditUnrecognizedPOA &&
    [APPELLANT_TYPES.OTHER_CLAIMANT, APPELLANT_TYPES.HEALTHCARE_PROVIDER_CLAIMANT].includes(
      appeal.appellantType
    ) && !appeal.hasPOA && props.featureToggles.edit_unrecognized_appellant_poa;

  const supportCavcRemand =
    currentUserIsOnCavcLitSupport && !appeal.isLegacyAppeal && appeal.issueCount > 0;

  const supportCavcDashboard = canViewCavcDashboards && appealHasRemandWithDashboard;

  const hasSubstitution = appealHasSubstitution(appeal);
  const supportPostDispatchSubstitution = supportsSubstitutionPostDispatch({
    appeal,
    currentUserOnClerkOfTheBoard,
    featureToggles,
    hasSubstitution,
    userIsCobAdmin
  });
  const supportPendingAppealSubstitution = supportsSubstitutionPreDispatch({
    appeal,
    currentUserOnClerkOfTheBoard,
    featureToggles,
    userIsCobAdmin
  });

  const showPostDispatch =
    appealIsDispatched && (supportCavcRemand || supportPostDispatchSubstitution || supportCavcDashboard);

  const actionableScheduledHearingTasks = useSelector(
    (state) => openScheduleHearingTasksForAppeal(state, { appealId: appeal.externalId })
  );
  const allScheduleHearingTasks = useSelector(
    (state) => scheduleHearingTasksForAppeal(state, { appealId: appeal.externalId })
  );
  const allHearingTasks = useSelector(
    (state) => allHearingTasksForAppeal(state, { appealId: appeal.externalId })
  );
  const parentHearingTasks = parentTasks(actionableScheduledHearingTasks, allHearingTasks);

  // Retrieve VSO convert to virtual success message after getting redirected from Hearings app
  const displayVSOAlert = JSON.parse(localStorage.getItem('VSOSuccessMsg'));

  localStorage.removeItem('VSOSuccessMsg');

  // Retrieve split appeal success and remove from the store
  const splitStorage = localStorage.getItem('SplitAppealSuccess');

  localStorage.removeItem('SplitAppealSuccess');

  // if null, leave null, if true, check if value is true with reg expression.
  const splitAppealSuccess = (splitStorage === null ? null : (/true/i).test(splitStorage));

  return (
    <React.Fragment>
      {(splitAppealSuccess && props.featureToggles.split_appeal_workflow) && (
        <div>
          <Alert
            type="success"
            title={`You have successfully split ${appeal.appellantFullName}'s appeal`}
            message="This new appeal stream has the same docket number and tasks as the original appeal."
          />
        </div>
      )}
      {(splitAppealSuccess === false && props.featureToggles.split_appeal_workflow) && (
        <div {...alertPaddingStyle}>
          <Alert title="Unable to Process Request" type="error">
            Something went wrong and the appeal was not split.
          </Alert>
        </div>
      )}
      {!modalIsOpen && error && (
        <div {...alertPaddingStyle}>
          <Alert title={error.title} type="error">
            {error.detail}
          </Alert>
        </div>
      )}
      {!modalIsOpen && success && (
        <div {...alertPaddingStyle}>
          <Alert type="success" title={success.title} scrollOnAlert={false}>
            {success.detail}
          </Alert>
        </div>
      )}
      {!modalIsOpen && showPostDispatch && (
        <CaseDetailsPostDispatchActions
          appealId={appealId}
          includeCavcRemand={supportCavcRemand}
          includeSubstitute={supportPostDispatchSubstitution}
          supportCavcDashboard={supportCavcDashboard}
        />
      )}
      {(!modalIsOpen || props.userCanScheduleVirtualHearings) && <UserAlerts />}
      {displayVSOAlert && (
        <div>
          <Alert
            type="success"
            title={displayVSOAlert.title}
            message={displayVSOAlert.detail}
          />
        </div>
      )}
      <AppSegment filledBackground>
        <CaseTitle appeal={appeal} />
        {supportPendingAppealSubstitution && (
          <div {...sectionGap}>
            <Button
              onClick={() =>
                push(`/queue/appeals/${appealId}/substitute_appellant`)
              }
            >
              {COPY.SUBSTITUTE_APPELLANT_BUTTON}
            </Button>
          </div>
        )}
        {appeal.veteranDateOfDeath && props.featureToggles.fnod_banner && (
          <FnodBanner appeal={appeal} />
        )}
        {shouldShowVsoVisibilityAlert({
          featureToggles,
          userIsVsoEmployee,
        }) && (
          <div className={topAlertStyles}>
            <VsoVisibilityAlert />
          </div>
        )}
        <CaseTitleDetails
          appealId={appealId}
          redirectUrl={window.location.pathname}
          userCanAccessReader={props.userCanAccessReader}
        />
        {veteranCaseListIsVisible && (
          <VeteranCasesView
            caseflowVeteranId={appeal.caseflowVeteranId}
            veteranId={appeal.veteranFileNumber}
          />
        )}
        <TaskSnapshot
          appealId={appealId}
          showPulacCerulloAlert={doPulacCerulloReminder}
        />
        <hr {...horizontalRuleStyling} />
        <StickyNavContentArea>
          <CaseDetailsIssueList
            title="Issues"
            isLegacyAppeal={appeal.isLegacyAppeal}
            additionalHeaderContent={
              appeal.canEditRequestIssues && (
                <span className="cf-push-right" {...anchorEditLinkStyling}>
                  <Link href={`/appeals/${appealId}/edit`}>
                    {COPY.CORRECT_REQUEST_ISSUES_LINK}
                  </Link>
                </span>
              )
            }
            issues={appeal.issues}
            decisionIssues={appeal.decisionIssues}
          />
          <PowerOfAttorneyDetail
            title={CASE_DETAILS_POA_SUBSTITUTE}
            appealId={appealId}
            additionalHeaderContent={
              editPOAInformation && (
                <span
                  className="cf-push-right"
                  {...editAppellantInformationLinkStyling}
                >
                  <Link to={`/queue/appeals/${appealId}/edit_poa_information`}>
                    {updatePOALink}
                  </Link>
                </span>
              )
            }
          />
          {(appeal.hearings.length ||
            appeal.completedHearingOnPreviousAppeal ||
            actionableScheduledHearingTasks.length ||
            // VSO users will not have any available task actions on the ScheduleHearingTask(s),
            // but prior to a hearing being scheduled they will need the Hearings section rendered anyways.
            (props.vsoVirtualOptIn && userIsVsoEmployee && allScheduleHearingTasks.length)
          ) && (
            <CaseHearingsDetail
              title="Hearings"
              appeal={appeal}
              hearingTasks={userIsVsoEmployee ? allScheduleHearingTasks : parentHearingTasks}
              vsoVirtualOptIn={props.vsoVirtualOptIn}
              currentUserEmailPresent={Boolean(appeal.currentUserEmail)}
            />
          )}
          <VeteranDetail title="About the Veteran" appealId={appealId} />
          {appeal.appellantIsNotVeteran && !_.isNull(appeal.appellantFullName) && (
            <AppellantDetail
              title="About the Appellant"
              appeal={appeal}
              substitutionDate={appeal.appellantSubstitution?.substitution_date} // eslint-disable-line camelcase
              additionalHeaderContent={
                editAppellantInformation && (
                  <span
                    className="cf-push-right"
                    {...editAppellantInformationLinkStyling}
                  >
                    <Link
                      to={`/queue/appeals/${appealId}/edit_appellant_information`}
                    >
                      {COPY.EDIT_APPELLANT_INFORMATION_LINK}
                    </Link>
                  </span>
                )
              }
            />
          )}

          {!_.isNull(appeal.cavcRemand) && appeal.cavcRemand && (
            <CavcDetail
              title="CAVC Remand"
              additionalHeaderContent={
                canEditCavcRemands && (
                  <span className="cf-push-right" {...anchorEditLinkStyling}>
                    <Link to={`/queue/appeals/${appealId}/edit_cavc_remand`}>
                      {COPY.CORRECT_CAVC_REMAND_LINK}
                    </Link>
                  </span>
                )
              }
              appealId = {appealId}
              canViewCavcDashboards = {canViewCavcDashboards}
              {...appeal.cavcRemand}
            />
          )}

          <CaseTimeline title="Case Timeline" appeal={appeal}
            additionalHeaderContent={
              true && (
                <span className="cf-push-right" {...anchorEditLinkStyling}>
                  { appeal.hasNotifications &&
                  <Link id="notification-link" href={`/queue/appeals/${appealId}/notifications`} target="_blank">
                    {COPY.VIEW_NOTIFICATION_LINK}
                    &nbsp;
                    <span {...ICON_POSITION_FIX}>
                      <ExternalLinkIcon color={COLORS.PRIMARY} size={ICON_SIZES.SMALL} />
                    </span>
                  </Link>}
                </span>
              )
            }
          />
        </StickyNavContentArea >
        {props.pollHearing && pollHearing()}
      </AppSegment>
    </React.Fragment>
  );
};

CaseDetailsView.propTypes = {
  appeal: PropTypes.object,
  appealId: PropTypes.string.isRequired,
  clearAlerts: PropTypes.func,
  tasks: PropTypes.array,
  error: PropTypes.object,
  featureToggles: PropTypes.object,
  resetErrorMessages: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  setHearingDay: PropTypes.func,
  success: PropTypes.object,
  userCanAccessReader: PropTypes.bool,
  veteranCaseListIsVisible: PropTypes.bool,
  userCanScheduleVirtualHearings: PropTypes.bool,
  userCanEditUnrecognizedPOA: PropTypes.bool,
  scheduledHearingId: PropTypes.string,
  pollHearing: PropTypes.bool,
  stopPollingHearing: PropTypes.func,
  substituteAppellant: PropTypes.object,
  vsoVirtualOptIn: PropTypes.bool,
  canViewCavcDashboards: PropTypes.bool
};

const mapStateToProps = (state) => ({
  scheduledHearingId: state.components.scheduledHearing.externalId,
  pollHearing: state.components.scheduledHearing.polling,
  featureToggles: state.ui.featureToggles,
  substituteAppellant: state.substituteAppellant,
  canViewCavcDashboards: state.ui.canViewCavcDashboards
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      clearAlerts,
      resetErrorMessages,
      resetSuccessMessages,
      transitionAlert,
      stopPollingHearing,
      setHearingDay
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseDetailsView);
/* eslint-enable max-lines */
