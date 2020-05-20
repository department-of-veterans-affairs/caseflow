import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { caseTimelineTasksForAppeal } from './selectors';
import COPY from '../../COPY';
import TaskRows from './components/TaskRows';

class CaseTimeline extends React.PureComponent {
  render = () => {
    const {
      appeal,
      tasks
    } = this.props;

    return <React.Fragment>
      <table id="case-timeline-table" summary="layout table">
        <tr><th style={{ border: 'none' }} colSpan="100%">{COPY.CASE_TIMELINE_HEADER}</th></tr>
        <tbody>
          <TaskRows appeal={appeal} taskList={tasks} timeline />
        </tbody>
      </table>
    </React.Fragment>;
  }
}

CaseTimeline.propTypes = {
  appeal: PropTypes.object,
  tasks: PropTypes.array
};

const mapStateToProps = (state, ownProps) => {
  return {
    tasks: caseTimelineTasksForAppeal(state, { appealId: ownProps.appeal.externalId })
  };
};

export default connect(mapStateToProps)(CaseTimeline);
