import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ReaderLink from './ReaderLink';
import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import TabWindow from '../components/TabWindow';
import SearchableDropdown from '../components/SearchableDropdown';

import { fullWidth, CATEGORIES } from './constants';
import { DateString } from '../util/DateUtil';

const headerStyling = css({
  marginBottom: '0.5rem'
});
const subHeadStyling = css({
  marginBottom: '2rem'
});

const draftDecisionOptions = [{
  label: 'Decision Ready for Review',
  value: 'decision'
}, {
  label: 'OMO Ready for Review',
  value: 'omo'
}];

class QueueDetailView extends React.PureComponent {
  render = () => {
    const {
      appeal: { attributes: appeal },
      task: { attributes: task }
    } = this.props;
    const tabs = [{
      label: 'Appeal',
      page: <AppealDetail appeal={this.props.appeal} />
    }, {
      label: `Appellant (${appeal.appellant_full_name || appeal.veteran_full_name})`,
      page: <AppellantDetail appeal={this.props.appeal} />
    }];

    const readerLinkMsg = appeal.docCount ?
      `Open ${appeal.docCount.toLocaleString()} documents in Caseflow Reader` :
      'Open documents in Caseflow Reader';

    return <AppSegment filledBackground>
      <h1 className="cf-push-left" {...css(headerStyling, fullWidth)}>
        Draft Decision - {appeal.veteran_full_name} ({appeal.vacols_id})
      </h1>
      <p className="cf-lead-paragraph" {...subHeadStyling}>
        Assigned to you {task.added_by_name ? `by ${task.added_by_name}` : ''} on&nbsp;
        <DateString date={task.assigned_on} dateFormat="MM/DD/YY" />.
        Due <DateString date={task.due_on} dateFormat="MM/DD/YY" />.
      </p>
      <ReaderLink vacolsId={this.props.vacolsId} message={readerLinkMsg}
        analyticsSource={CATEGORIES.QUEUE_TASK} />
      {this.props.featureToggles.phase_two && <SearchableDropdown
        name="Select an action"
        placeholder="Select an action"
        options={draftDecisionOptions}
        onChange={_.noop}
        hideLabel
        searchable={false} />}

      <TabWindow
        name="queue-tabwindow"
        tabs={tabs} />
    </AppSegment>;
  };
}

QueueDetailView.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId],
  task: state.queue.loadedQueue.tasks[ownProps.vacolsId]
});

export default connect(mapStateToProps)(QueueDetailView);
