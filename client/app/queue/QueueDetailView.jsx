import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ReaderLink from './ReaderLink';
import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import TabWindow from '../components/TabWindow';
import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';

import {
  fullWidth,
  CATEGORIES
} from './constants';
import { DateString } from '../util/DateUtil';
import { resetBreadcrumbs } from './uiReducer/uiActions';

const headerStyling = css({ marginBottom: '0.5rem' });
const subHeadStyling = css({ marginBottom: '2rem' });

class QueueDetailView extends React.PureComponent {
  componentDidMount = () => {
    const {
      appeal: { attributes: { veteran_full_name: vetName } },
      vacolsId
    } = this.props;

    this.props.resetBreadcrumbs(vetName, vacolsId);
  }

  render = () => {
    const {
      vacolsId,
      appeal: { attributes: appeal },
      task: { attributes: task }
    } = this.props;
    const tabs = [{
      label: 'Appeal',
      page: <AppealDetail appeal={this.props.appeal} analyticsSource={CATEGORIES.QUEUE_TASK} />
    }, {
      label: `Appellant (${appeal.appellant_full_name || appeal.veteran_full_name})`,
      page: <AppellantDetail appeal={this.props.appeal} analyticsSource={CATEGORIES.QUEUE_TASK} />
    }];

    return <AppSegment filledBackground>
      <h1 className="cf-push-left" {...css(headerStyling, fullWidth)}>
        {appeal.veteran_full_name} ({appeal.vbms_id})
      </h1>
      <p className="cf-lead-paragraph" {...subHeadStyling}>
        Assigned to you {task.added_by_name ? `by ${task.added_by_name}` : ''} on&nbsp;
        <DateString date={task.assigned_on} dateFormat="MM/DD/YY" />.
        Due <DateString date={task.due_on} dateFormat="MM/DD/YY" />.
      </p>
      <ReaderLink
        vacolsId={this.props.vacolsId}
        analyticsSource={CATEGORIES.QUEUE_TASK}
        redirectUrl={window.location.pathname}
        docCount={appeal.docCount}
        taskType="Draft Decision"
        longMessage />
      {this.props.featureToggles.phase_two && <SelectCheckoutFlowDropdown vacolsId={vacolsId} />}
      <TabWindow
        name="queue-tabwindow"
        tabs={tabs} />
    </AppSegment>;
  };
}

QueueDetailView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId],
  task: state.queue.loadedQueue.tasks[ownProps.vacolsId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  resetBreadcrumbs
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueDetailView);
