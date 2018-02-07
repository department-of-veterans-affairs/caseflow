import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { connect } from 'react-redux';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ReaderLink from './ReaderLink';
import TabWindow from '../components/TabWindow';

import { fullWidth } from './constants';
import { DateString } from '../util/DateUtil';

const headerStyling = css({
  width: '100%',
  marginBottom: '0.5rem'
});
const subHeadStyling = css({
  marginBottom: '2rem'
});

class QueueDetailView extends React.PureComponent {
  render = () => {
    const {
      appeal: { attributes: appeal },
      task: { attributes: task }
    } = this.props;
    const tabs = [{
      label: 'Appeal',
      page: 'TODO: Appeal Summary page'
    }, {
      label: `Appellant (${appeal.veteran_full_name})`,
      page: 'TODO: Appellant detail page'
    }];

    const readerLinkMsg = appeal.docCount ?
      `Open ${appeal.docCount.toLocaleString()} documents in Caseflow Reader` :
      'Open documents in Caseflow Reader';

    return <AppSegment filledBackground>
      <h1 className="cf-push-left" {...headerStyling}>
        Draft Decision - {appeal.veteran_full_name} ({appeal.vacols_id})
      </h1>
      <p className="cf-lead-paragraph" {...subHeadStyling}>
        Assigned to you {task.added_by_name ? `by ${task.added_by_name}` : ''} on&nbsp;
        <DateString date={task.assigned_on} dateFormat="MM/DD/YY" />.
        Due <DateString date={task.due_on} dateFormat="MM/DD/YY" />.
      </p>
      <ReaderLink vacolsId={this.props.vacolsId} message={readerLinkMsg} />

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
