import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import {
  appealWithDetailSelector,
  taskSnapshotTasksForAppeal
} from './selectors';
import AddNewTaskButton from './components/AddNewTaskButton';
import TaskRows from './components/TaskRows';
import COPY from '../../COPY.json';
import type { Appeal } from './types/models';
import type { State } from './types/state';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling
} from './StickyNavContentArea';

const tableStyling = css({
  width: '100%',
  marginTop: '0px'
});

type Params = {|
  appealId: string,
  hideDropdown?: boolean
|};

type Props = Params & {|
  appeal: Appeal
|};

export class TaskSnapshot extends React.PureComponent<Props> {

  render = () => {
    const {
      appeal,
      tasks
    } = this.props;

    let sectionBody = COPY.TASK_SNAPSHOT_NO_ACTIVE_LABEL;

    if (tasks.length) {
      sectionBody = <table {...tableStyling}>
        <tbody>
          { <TaskRows appeal={appeal} taskList={tasks} timeline={false} /> }
        </tbody>
      </table>;
    }

    return <div className="usa-grid" {...css({ marginTop: '3rem' })}>
      <h2 {...sectionHeadingStyling}>
        <a id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.TASK_SNAPSHOT_ACTIVE_TASKS_LABEL}</a>
        { <AddNewTaskButton appealId={appeal.externalId} /> }
      </h2>
      <div {...sectionSegmentStyling}>
        { sectionBody }
      </div>
    </div>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    tasks: taskSnapshotTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(TaskSnapshot);
