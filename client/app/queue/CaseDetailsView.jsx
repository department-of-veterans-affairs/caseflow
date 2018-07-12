import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Alert from '../components/Alert';
import AppellantDetail from './AppellantDetail';
import CaseHearingsDetail from './CaseHearingsDetail';
import CaseTitle from './CaseTitle';
import CaseSnapshot from './CaseSnapshot';
import CaseDetailsIssueList from './components/CaseDetailsIssueList';
import StickyNavContentArea from './StickyNavContentArea';
import { CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS } from '../constants/AppConstants';

import { clearActiveAppealAndTask } from './CaseDetail/CaseDetailActions';
import { pushBreadcrumb, resetBreadcrumbs } from './uiReducer/uiActions';

// TODO: Pull this horizontal rule styling out somewhere.
const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '3rem',
  marginBottom: '3rem'
});

const PowerOfAttorneyDetail = ({ poa }) => <p>{poa.representative_type} - {poa.representative_name}</p>;

class CaseDetailsView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.clearActiveAppealAndTask();
  }

  componentDidMount = () => {
    window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);

    if (!this.props.breadcrumbs.length) {
      this.props.resetBreadcrumbs(this.props.appeal.attributes.veteran_full_name, this.props.appealId);
    }
  }

  render = () => <AppSegment filledBackground>
    <CaseTitle appeal={this.props.appeal} appealId={this.props.appealId} redirectUrl={window.location.pathname} />
    {this.props.error && <Alert title={this.props.error.title} type="error">
      {this.props.error.detail}
    </Alert>}
    <CaseSnapshot
      appeal={this.props.appeal}
      loadedQueueAppealIds={this.props.loadedQueueAppealIds}
      task={this.props.task}
    />
    <hr {...horizontalRuleStyling} />
    <StickyNavContentArea>
      <CaseDetailsIssueList
        title="Issues"
        isLegacyAppeal={this.props.appeal.attributes.is_legacy_appeal}
        issues={this.props.appeal.attributes.issues}
      />
      <PowerOfAttorneyDetail title="Power of Attorney" poa={this.props.appeal.attributes.power_of_attorney} />
      { this.props.appeal.attributes.hearings.length &&
      <CaseHearingsDetail title="Hearings" appeal={this.props.appeal} /> }
      <AppellantDetail title="About the Veteran" appeal={this.props.appeal} />
    </StickyNavContentArea>
  </AppSegment>;
}

CaseDetailsView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state) => ({
  appeal: state.caseDetail.activeAppeal,
  ..._.pick(state.ui, 'breadcrumbs'),
  error: state.ui.messages.error,
  task: state.caseDetail.activeTask,
  loadedQueueAppealIds: Object.keys(state.queue.loadedQueue.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearActiveAppealAndTask,
  pushBreadcrumb,
  resetBreadcrumbs
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseDetailsView);
