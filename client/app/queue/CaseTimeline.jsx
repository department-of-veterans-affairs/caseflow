import React from 'react';
import { connect } from 'react-redux';
import type { State } from './types/state';
import { allCompleteTasksForAppeal } from './selectors';
import COPY from '../../COPY.json';
import TaskRows from './components/TaskRows';
import _ from 'lodash';

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

  let completedTasks = allCompleteTasksForAppeal(state, { appealId: ownProps.appeal.externalId });

  completedTasks = _.orderBy(completedTasks, ['completedOn'], ['desc']);

  return {
    completedTasks
  };
};

export default connect(mapStateToProps)(CaseTimeline);
