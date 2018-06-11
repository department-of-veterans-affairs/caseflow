import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import CaseTitle from './CaseTitle';
import CaseSnapshot from './CaseSnapshot';
import TabWindow from '../components/TabWindow';
import { CATEGORIES } from './constants';

import { clearActiveAppealAndTask } from './CaseDetail/CaseDetailActions';
import { pushBreadcrumb, resetBreadcrumbs } from './uiReducer/uiActions';

class QueueDetailView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.clearActiveAppealAndTask();
  }

  componentDidMount = () => {
    if (!this.props.breadcrumbs.length) {
      this.props.resetBreadcrumbs(this.props.appeal.attributes.veteran_full_name, this.props.vacolsId);
    }
  }

  tabs = () => {
    const appeal = this.props.appeal;

    return [{
      label: 'Appeal',
      page: <AppealDetail appeal={appeal} analyticsSource={CATEGORIES.QUEUE_TASK} />
    }, {
      label: `Appellant (${appeal.attributes.appellant_full_name || appeal.attributes.veteran_full_name})`,
      page: <AppellantDetail appeal={appeal} analyticsSource={CATEGORIES.QUEUE_TASK} />
    }];
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
    <TabWindow
      name="queue-tabwindow"
      tabs={this.tabs()} />
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
