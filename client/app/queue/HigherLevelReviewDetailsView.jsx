import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ContestedIssues from './components/ContestedIssues';

import Alert from '../components/Alert';
import AppellantDetail from './AppellantDetail';
import VeteranDetail from './VeteranDetail';
import VeteranCasesView from './VeteranCasesView';
import CaseHearingsDetail from './CaseHearingsDetail';
import PowerOfAttorneyDetail from './PowerOfAttorneyDetail';
import CaseTitle from './CaseTitle';
import CaseSnapshot from './CaseSnapshot';
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

class HigherLevelReviewDetailsView extends React.PureComponent {
  render = () => {
    const {
      appealId,
      appealType,
      appeal,
      error,
      success,
      featureToggles
    } = this.props;

    return <AppSegment filledBackground>
      <CaseSnapshot appealId={appealId} appealType={appealType} />
      <h1>Decision</h1>
      Review each issue and select a disposition.
      <ContestedIssues requestIssues={appeal.issues} decisionIssues={[]} openDecisionHandler={() => {}}/>
    </AppSegment>;
  };
}

HigherLevelReviewDetailsView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const { success, error } = state.ui.messages;
  const { veteranCaseListIsVisible, featureToggles } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId, appealType: ownProps.appealType }),
    success,
    featureToggles,
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

export default connect(mapStateToProps, mapDispatchToProps)(HigherLevelReviewDetailsView);
