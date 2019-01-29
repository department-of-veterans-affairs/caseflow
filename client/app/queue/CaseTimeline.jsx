import React from 'react';
import { connect } from 'react-redux';
import type { State } from './types/state';
import { caseTimelineTasksForAppeal } from './selectors';
import COPY from '../../COPY.json';
import TaskRows from './components/TaskRows';

type Params = {|
  appealId: string
|};

class CaseTimeline extends React.PureComponent {
  render = () => {
    const {
      appeal,
      tasks
    } = this.props;

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table>
        <tbody>
          { <TaskRows appeal={appeal} taskList={tasks} timeline /> }
        </tbody>
      </table>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  return {
    tasks: caseTimelineTasksForAppeal(state, { appealId: ownProps.appeal.externalId })
  };
};

export default connect(mapStateToProps)(CaseTimeline);
