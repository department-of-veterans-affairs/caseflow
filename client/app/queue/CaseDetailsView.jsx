import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useEffect, useMemo } from 'react';
import { connect, useSelector } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Alert from '../components/Alert';
import AppellantDetail from './AppellantDetail';
import VeteranDetail from './VeteranDetail';
import VeteranCasesView from './VeteranCasesView';
import CaseHearingsDetail from './CaseHearingsDetail';
import PowerOfAttorneyDetail from './PowerOfAttorneyDetail';
import CaseTitle from './CaseTitle';
import CaseTitleDetails from './CaseTitleDetails';
import TaskSnapshot from './TaskSnapshot';
import CaseDetailsIssueList from './components/CaseDetailsIssueList';
import StickyNavContentArea from './StickyNavContentArea';
import { resetErrorMessages, resetSuccessMessages, setHearingDay } from './uiReducer/uiActions';
import CaseTimeline from './CaseTimeline';
import { getQueryParams } from '../util/QueryParamsUtil';

import { CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS } from '../constants/AppConstants';
import COPY from '../../COPY';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { appealWithDetailSelector, getAllTasksForAppeal } from './selectors';
import { needsPulacCerulloAlert } from './pulacCerullo';

// TODO: Pull this horizontal rule styling out somewhere.
const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '3rem',
  marginBottom: '3rem'
});

const anchorEditLinkStyling = css({
  fontSize: '1.5rem',
  fontWeight: 'normal',
  margin: '5px'
});

const alertPaddingStyle = css({
  marginTop: '2rem'
});

export const CaseDetailsView = (props) => {
  const { appealId } = props;
  const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));
  const tasks = useSelector((state) => getAllTasksForAppeal(state, { appealId }));

  const success = useSelector((state) => state.ui.messages.success);
  const error = useSelector((state) => state.ui.messages.error);
  const veteranCaseListIsVisible = useSelector((state) => state.ui.veteranCaseListIsVisible);

  useEffect(() => {
    window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);
    props.resetErrorMessages();

    const { hearingDate, regionalOffice } = getQueryParams(window.location.search);

    if (hearingDate && regionalOffice) {
      props.setHearingDay({
        hearingDate,
        regionalOffice
      });
    }
  }, []);

  const doPulacCerulloReminder = useMemo(() => needsPulacCerulloAlert(appeal, tasks), [appeal, tasks]);

  return (
    <React.Fragment>
      {error && (
        <div {...alertPaddingStyle}>
          <Alert title={error.title} type="error">
            {error.detail}
          </Alert>
        </div>
      )}
      {success && (
        <div {...alertPaddingStyle}>
          <Alert type="success" title={success.title} scrollOnAlert={false}>
            {success.detail}
          </Alert>
        </div>
      )}
      <AppSegment filledBackground>
        <CaseTitle appeal={appeal} />
        <CaseTitleDetails
          appealId={appealId}
          redirectUrl={window.location.pathname}
          userCanAccessReader={props.userCanAccessReader}
        />
        {veteranCaseListIsVisible && (
          <VeteranCasesView caseflowVeteranId={appeal.caseflowVeteranId} veteranId={appeal.veteranFileNumber} />
        )}
        <TaskSnapshot appealId={appealId} showPulacCerulloAlert={doPulacCerulloReminder} />
        <hr {...horizontalRuleStyling} />
        <StickyNavContentArea>
          <CaseDetailsIssueList
            title="Issues"
            isLegacyAppeal={appeal.isLegacyAppeal}
            additionalHeaderContent={
              appeal.canEditRequestIssues && (
                <span className="cf-push-right" {...anchorEditLinkStyling}>
                  <Link href={`/appeals/${appealId}/edit`}>{COPY.CORRECT_REQUEST_ISSUES_LINK}</Link>
                </span>
              )
            }
            issues={appeal.issues}
            decisionIssues={appeal.decisionIssues}
          />
          <PowerOfAttorneyDetail title="Power of Attorney" appealId={appealId} />
          {(appeal.hearings.length || appeal.completedHearingOnPreviousAppeal) && (
            <CaseHearingsDetail title="Hearings" appeal={appeal} />
          )}
          <VeteranDetail title="About the Veteran" appeal={appeal} />
          {!_.isNull(appeal.appellantFullName) && appeal.appellantIsNotVeteran && (
            <AppellantDetail title="About the Appellant" appeal={appeal} />
          )}
          <CaseTimeline title="Case Timeline" appeal={appeal} />}
        </StickyNavContentArea>
      </AppSegment>
    </React.Fragment>
  );
};

CaseDetailsView.propTypes = {
  appeal: PropTypes.object,
  appealId: PropTypes.string.isRequired,
  tasks: PropTypes.array,
  error: PropTypes.object,
  resetErrorMessages: PropTypes.func,
  setHearingDay: PropTypes.func,
  success: PropTypes.object,
  userCanAccessReader: PropTypes.bool,
  veteranCaseListIsVisible: PropTypes.bool
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      resetErrorMessages,
      resetSuccessMessages,
      setHearingDay
    },
    dispatch
  );

export default connect(
  null,
  mapDispatchToProps
)(CaseDetailsView);
