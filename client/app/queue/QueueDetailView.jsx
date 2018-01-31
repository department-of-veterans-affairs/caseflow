import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { connect } from 'react-redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ReaderLink from './ReaderLink';
import TabWindow from '../components/TabWindow';
import AppealSummary from './AppealSummary';

import { redText } from './constants';

class QueueDetailView extends React.PureComponent {
  render = () => {
    const appeal = this.props.appeal.attributes;
    const tabs = [{
      label: 'Appeal',
      page: <AppealSummary appeal={this.props.appeal}/>
    }, {
      label: `Appellant (${appeal.veteran_full_name})`,
      page: 'TODO: Appellant detail page'
    }];

    return <AppSegment filledBackground>
      <h1 className="cf-push-left cf-form--full-width">
        {`Draft Decision - ${appeal.veteran_full_name} (${appeal.vacols_id})`}
      </h1>
      <p className="cf-lead-paragraph">
        Assigned to you by <span {...redText}>Judge</span> on {moment(this.props.task.attributes.assigned_on).format('MM/DD/YY')}.
        Due {moment(this.props.task.attributes.due_on).format('MM/DD/YY')}
      </p>
      <ReaderLink appealId={this.props.appealId} message="Open documents in Caseflow Reader" />

      <TabWindow
        name="queue-tabwindow"
        tabs={tabs} />
    </AppSegment>;
  };
}

QueueDetailView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  // todo: rename appealId to vacolsId
  appeal: state.queue.loadedQueue.appeals[ownProps.appealId],
  task: state.queue.loadedQueue.tasks[ownProps.appealId]
});

export default connect(mapStateToProps)(QueueDetailView);
