import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React, { useEffect, useMemo } from 'react';
import _ from 'lodash';

import { APPELLANT_TYPES, CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS } from '../constants/AppConstants';
import {
  appealWithDetailSelector,
  getAllTasksForAppeal,
  openScheduleHearingTasksForAppeal,
  allHearingTasksForAppeal
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
import CavcDetail from './CavcDetail';
import CaseDetailsPostDispatchActions from './CaseDetailsPostDispatchActions';
import PowerOfAttorneyDetail from './PowerOfAttorneyDetail';
import StickyNavContentArea from './StickyNavContentArea';
import TaskSnapshot from './TaskSnapshot';
import UserAlerts from '../components/UserAlerts';
import VeteranCasesView from './VeteranCasesView';
import VeteranDetail from './VeteranDetail';
import { startPolling } from '../hearings/utils';
import FnodBanner from './components/FnodBanner';
import { shouldSupportSubstituteAppellant } from './substituteAppellant/caseDetails/utils';
import { VsoVisibilityAlert } from './caseDetails/VsoVisibilityAlert';
import { shouldShowVsoVisibilityAlert } from './caseDetails/utils';

// TODO: Pull this horizontal rule styling out somewhere.
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

const editAppellantInformationLinkStyling = css({
  fontSize: '2rem',
  fontWeight: 'normal',
  margin: '5px',
});

const topAlertStyles = css({ marginBottom: '2.4rem' });

export const CaseDetailsView = (props) => {
  const { appealId, featureToggles } = props;
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
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

  const appealIsDispatched = ['dispatched', 'post_dispatch'].includes(appeal.status);

  const editAppellantInformation =
    appeal.appellantType === APPELLANT_TYPES.OTHER_CLAIMANT && props.featureToggles.edit_unrecognized_appellant;

  const supportCavcRemand =
    currentUserIsOnCavcLitSupport && props.featureToggles.cavc_remand && !appeal.isLegacyAppeal;

  const hasSubstitution = appeal.substitutions?.length;
  const supportSubstituteAppellant = shouldSupportSubstituteAppellant({
    appeal,
    currentUserOnClerkOfTheBoard,
    featureToggles,
    hasSubstitution,
    userIsCobAdmin
  });

  const showPostDispatch =
    appealIsDispatched && (supportCavcRemand || supportSubstituteAppellant);

  const openScheduledHearingTasks = useSelector(
    (state) => openScheduleHearingTasksForAppeal(state, { appealId: appeal.externalId })
  );
  const allHearingTasks = useSelector(
    (state) => allHearingTasksForAppeal(state, { appealId: appeal.externalId })
  );
  const parentHearingTasks = parentTasks(openScheduledHearingTasks, allHearingTasks);

  return (
    <React.Fragment>
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
          includeSubstitute={supportSubstituteAppellant}
        />
      )}
      {(!modalIsOpen || props.userCanScheduleVirtualHearings) && <UserAlerts />}
      <AppSegment filledBackground>
        <CaseTitle appeal={appeal} />
        {appeal.veteranDateOfDeath && props.featureToggles.fnod_banner && (
          <FnodBanner appeal={appeal} />
        )}
        {shouldShowVsoVisibilityAlert({ featureToggles, userIsVsoEmployee }) && (
          <div className={topAlertStyles}><VsoVisibilityAlert /></div>
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
              editAppellantInformation && (
                <span className="cf-push-right">
                  <Link to={`/queue/appeals/${appealId}/edit_poa_information`}>
                    {"edit"}
                  </Link>
                </span>
              )
            }
          />
          {(appeal.hearings.length ||
            appeal.completedHearingOnPreviousAppeal ||
            openScheduledHearingTasks.length) && (
            <CaseHearingsDetail title="Hearings" appeal={appeal} hearingTasks={parentHearingTasks} />
          )}
          <VeteranDetail title="About the Veteran" appealId={appealId} />
          {appeal.appellantIsNotVeteran && !_.isNull(appeal.appellantFullName) && (
            <AppellantDetail
              title="About the Appellant"
              appeal={appeal}
              substitutionDate={appeal.appellantSubstitution?.substitution_date} // eslint-disable-line camelcase
              additionalHeaderContent={
                editAppellantInformation && (
                  <span className="cf-push-right" {...editAppellantInformationLinkStyling}>
                    <Link to={`/queue/appeals/${appealId}/edit_appellant_information`}>
                      {COPY.EDIT_APPELLANT_INFORMATION_LINK}
                    </Link>
                  </span>
                )
              }
            />
          ) }

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
              {...appeal.cavcRemand}
            />
          )}

          <CaseTimeline title="Case Timeline" appeal={appeal} />
        </StickyNavContentArea>
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
  setHearingDay: PropTypes.func,
  success: PropTypes.object,
  userCanAccessReader: PropTypes.bool,
  veteranCaseListIsVisible: PropTypes.bool,
  userCanScheduleVirtualHearings: PropTypes.bool,
  scheduledHearingId: PropTypes.string,
  pollHearing: PropTypes.bool,
  stopPollingHearing: PropTypes.func,
  substituteAppellant: PropTypes.object,
};

const mapStateToProps = (state) => ({
  scheduledHearingId: state.components.scheduledHearing.externalId,
  pollHearing: state.components.scheduledHearing.polling,
  featureToggles: state.ui.featureToggles,
  substituteAppellant: state.substituteAppellant,
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      clearAlerts,
      resetErrorMessages,
      resetSuccessMessages,
      transitionAlert,
      stopPollingHearing,
      setHearingDay,
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseDetailsView);
