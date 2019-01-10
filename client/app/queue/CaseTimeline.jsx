import React from 'react';
import { connect } from 'react-redux';
import type { State } from './types/state';
import { allCompleteTasksForAppeal } from './selectors';
import COPY from '../../COPY.json';
import TaskRows from './components/TaskRows';

type Params = {|
  appealId: string
|};

class CaseTimeline extends React.PureComponent {
  render = () => {
    const {
      appeal
    } = this.props;

    return <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table>
        <tbody>
          { <TaskRows appeal={appeal} taskList={this.props.completedTasks} timeline /> }
        </tbody>
      </table>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {

  return {
    completedTasks: allCompleteTasksForAppeal(state, { appealId: ownProps.appeal.externalId })
  };
};

export default connect(mapStateToProps)(CaseTimeline);
