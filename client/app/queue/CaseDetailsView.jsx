import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
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
import { CaseTimeline } from './CaseTimeline';
import { getQueryParams } from '../util/QueryParamsUtil';

import { CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS } from '../constants/AppConstants';

import {
  appealWithDetailSelector
} from './selectors';

// TODO: Pull this horizontal rule styling out somewhere.
const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '3rem',
  marginBottom: '3rem'
});

class CaseDetailsView extends React.PureComponent {
  componentDidMount = () => {
    window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);
    this.props.resetErrorMessages();

    const { hearingDate, regionalOffice, hearingTime } = getQueryParams(window.location.search);

    if (hearingDate && regionalOffice) {
      this.props.setHearingDay({
        hearingDate,
        hearingTime: decodeURIComponent(hearingTime),
        regionalOffice
      });
    }
  }

  render = () => {
    const {
      appealId,
      appeal,
      error,
      canEditRequestIssues,
      success,
      featureToggles
    } = this.props;

    const amaIssueType = featureToggles.ama_decision_issues || !_.isEmpty(appeal.decisionIssues);

    return <AppSegment filledBackground>
      <CaseTitle appeal={appeal} />
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      {success && <Alert type="success" title={success.title} scrollOnAlert={false}>
        {success.detail}
      </Alert>}
      <CaseTitleDetails appealId={appealId} redirectUrl={window.location.pathname} />
      { this.props.veteranCaseListIsVisible &&
        <VeteranCasesView
          caseflowVeteranId={appeal.caseflowVeteranId}
          veteranId={appeal.veteranFileNumber}
        />
      }
      <TaskSnapshot appealId={appealId} />
      <hr {...horizontalRuleStyling} />
      <StickyNavContentArea>
        <CaseDetailsIssueList
          amaIssueType={amaIssueType}
          title="Issues"
          isLegacyAppeal={appeal.isLegacyAppeal}
          editLink={amaIssueType && canEditRequestIssues && `/appeals/${appealId}/edit`}
          issues={appeal.issues}
          decisionIssues={appeal.decisionIssues}
        />
        <PowerOfAttorneyDetail title="Power of Attorney" appealId={appealId} />
        {(appeal.hearings.length || appeal.completedHearingOnPreviousAppeal) &&
        <CaseHearingsDetail title="Hearings" appeal={appeal} />}
        <VeteranDetail title="About the Veteran" appeal={appeal} />
        {!_.isNull(appeal.appellantFullName) &&
        <AppellantDetail title="About the Appellant" appeal={appeal} />}
        <CaseTimeline title="Case Timeline" appeal={appeal} />}
      </StickyNavContentArea>
    </AppSegment>;
  };
}

CaseDetailsView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const { success, error } = state.ui.messages;
  const { veteranCaseListIsVisible, featureToggles, canEditRequestIssues } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    success,
    featureToggles,
    canEditRequestIssues,
    error,
    veteranCaseListIsVisible
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    resetErrorMessages,
    resetSuccessMessages,
    setHearingDay
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(CaseDetailsView);
