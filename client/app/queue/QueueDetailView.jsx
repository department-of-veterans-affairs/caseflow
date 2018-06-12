import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import AppellantDetail from './AppellantDetail';
import CaseHearingsDetail from './CaseHearingsDetail';
import CaseTitle from './CaseTitle';
import CaseSnapshot from './CaseSnapshot';
import IssueList from './components/IssueList';
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

// TODO: Move this out to its own component when it gets complex.
const PowerOfAttorneyDetail = ({ appeal }) => <p>{appeal.attributes.power_of_attorney}</p>;

class QueueDetailView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.clearActiveAppealAndTask();
  }

  componentDidMount = () => {
    window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);

    if (!this.props.breadcrumbs.length) {
      this.props.resetBreadcrumbs(this.props.appeal.attributes.veteran_full_name, this.props.vacolsId);
    }
  }

  render = () => <AppSegment filledBackground>
    <CaseTitle appeal={this.props.appeal} vacolsId={this.props.vacolsId} redirectUrl={window.location.pathname} />
    <CaseSnapshot
      appeal={this.props.appeal}
      featureToggles={this.props.featureToggles}
      loadedQueueAppealIds={this.props.loadedQueueAppealIds}
      task={this.props.task}
      userRole={this.props.userRole}
    />
    <hr {...horizontalRuleStyling} />
    <StickyNavContentArea>
      <IssueList title="Issues" appeal={_.pick(this.props.appeal.attributes, 'issues')} />
      <PowerOfAttorneyDetail title="Power of Attorney" appeal={this.props.appeal} />
      { this.props.appeal.attributes.hearings.length &&
        <CaseHearingsDetail title="Hearings" appeal={this.props.appeal} /> }
      <AppellantDetail title="About the Veteran" appeal={this.props.appeal} />
    </StickyNavContentArea>
  </AppSegment>;
}

QueueDetailView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  featureToggles: PropTypes.object,
  userRole: PropTypes.string
};

const mapStateToProps = (state) => ({
  appeal: state.caseDetail.activeAppeal,
  ..._.pick(state.ui, 'breadcrumbs', 'featureToggles', 'userRole'),
  task: state.caseDetail.activeTask,
  loadedQueueAppealIds: Object.keys(state.queue.loadedQueue.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearActiveAppealAndTask,
  pushBreadcrumb,
  resetBreadcrumbs
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueDetailView);
