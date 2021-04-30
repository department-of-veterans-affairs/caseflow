import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React, { useEffect, useMemo } from 'react';
import _ from 'lodash';

import { CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS } from '../constants/AppConstants';
import { appealWithDetailSelector, getAllTasksForAppeal } from './selectors';
import {
  stopPollingHearing,
  transitionAlert,
  clearAlerts,
} from '../components/common/actions';
import { getQueryParams } from '../util/QueryParamsUtil';
import { needsPulacCerulloAlert } from './pulacCerullo';
import {
  resetErrorMessages,
  resetSuccessMessages,
  setHearingDay,
} from './uiReducer/uiActions';
import Alert from '../components/Alert';
import AppellantDetail from './AppellantDetail';
import COPY from '../../COPY';
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

export const CaseDetailsView = (props) => {
  const { appealId } = props;
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
  const tasks = useSelector((state) =>
    getAllTasksForAppeal(state, { appealId })
  );
  const canEditCavcRemands = useSelector(
    (state) => state.ui.canEditCavcRemands
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

  const appealIsDispatched = appeal.status === 'dispatched';
  // I think we want this instead, but it's kind of off-topic here:
  // const appealIsDispatched = ['dispatched', 'post_dispatch'].includes(appeal.status);

  // Is CAVC remand supported?
  const supportCavcRemand =
    currentUserIsOnCavcLitSupport && props.featureToggles.cavc_remand;

  // We still need to check whether appeal.decisionIssues includes any
  // where disposition==='death_dismissal'
  // And, you know, tests.
  const supportSubstituteAppellant =
    currentUserOnClerkOfTheBoard &&
    props.featureToggles.recognized_granted_substitution_after_dd &&
    appeal.caseType === 'Original' && // original, vacate, de_novo, court_remand
    appeal.docketType !== 'hearing' &&
    appeal.decisionIssuesStatus;

  // Should we show a post-dispatch box?
  // Both CAVC remands and substitute appellants are AMA-only.
  const showPostDispatch =
    appealIsDispatched && (supportCavcRemand || supportSubstituteAppellant) &&
      !appeal.isLegacyAppeal;

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
            title="Appellant's Power of Attorney"
            appealId={appealId}
          />
          {(appeal.hearings.length ||
            appeal.completedHearingOnPreviousAppeal) && (
            <CaseHearingsDetail title="Hearings" appeal={appeal} />
          )}
          <VeteranDetail title="About the Veteran" appealId={appealId} />
          {!_.isNull(appeal.appellantFullName) &&
            appeal.appellantIsNotVeteran && (
            <AppellantDetail title="About the Appellant" appeal={appeal} />
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
};

const mapStateToProps = (state) => ({
  scheduledHearingId: state.components.scheduledHearing.externalId,
  pollHearing: state.components.scheduledHearing.polling,
  featureToggles: state.ui.featureToggles,
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
