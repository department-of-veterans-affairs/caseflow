import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { caseTimelineTasksForAppeal } from './selectors';
import COPY from '../../COPY';
import TaskRows from './components/TaskRows';

export class CaseTimeline extends React.PureComponent {
  render = () => {
    const {
      appeal,
      tasks
    } = this.props;

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table id="case-timeline-table" summary="layout table">
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
