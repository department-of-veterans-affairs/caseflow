import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';

import {
  appealWithDetailSelector,
  nonRootActionableTasksForAppeal,
  getAllTasksForAppeal
} from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import OnHoldLabel from './components/OnHoldLabel';
import AddNewTaskButton from './components/AddNewTaskButton';
import TaskRows from './components/TaskRows';
import COPY from '../../COPY.json';
import { DateString } from '../util/DateUtil';
import type { Appeal } from './types/models';
import type { State } from './types/state';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling
} from './StickyNavContentArea';
import Button from '../components/Button';

const taskContainerStyling = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px',
  paddingBottom: '3rem'
});

const taskTimeContainerStyling = css(taskContainerStyling, { width: '20%' });
const taskInformationContainerStyling = css(taskContainerStyling, { width: '25%' });
const taskActionsContainerStyling = css(taskContainerStyling, { width: '50%' });

const tableStyling = css({
  width: '100%',
  marginTop: '0px'
});

type Params = {|
  appealId: string,
  hideDropdown?: boolean
|};

type Props = Params & {|
  userRole: string,
  appeal: Appeal
|};

export class TaskSnapshot extends React.PureComponent<Props> {

  addedByNameListItem = (task) => {
    return task.addedByName ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
      <dd>{task.addedByName}</dd></div> : null;
  }

  render = () => {
    const {
      appeal
    } = this.props;

    let sectionBody = COPY.TASK_SNAPSHOT_NO_ACTIVE_LABEL;
    const tasks = this.props.tasks;
    const taskLength = tasks.length;

    if (taskLength) {
      sectionBody = <table {...tableStyling}>
        <tbody>
          { <TaskRows appeal={appeal} taskList={tasks} /> }
          { /* tasks.map((task, index) =>
            <tr key={task.uniqueId}>
              <td {...taskTimeContainerStyling}>
                <CaseDetailsDescriptionList>
                  { this.assignedOnListItem(task) }
                  { this.dueDateListItem(task) }
                  { this.daysWaitingListItem(task) }
                </CaseDetailsDescriptionList>
              </td>
              <td {...taskInfoWithIconContainer}><GrayDot />
                { (index + 1 < taskLength) && <div {...grayLineStyling} /> }
              </td>
              <td {...taskInformationContainerStyling}>
                <CaseDetailsDescriptionList>
                  { this.assignedToListItem(task) }
                  { this.assignedByListItem(task) }
                  { this.taskLabelListItem(task) }
                  { this.taskInstructionsListItem(task) }
                </CaseDetailsDescriptionList>
              </td>
              <td {...taskActionsContainerStyling}>
                { this.showActionsListItem(task, appeal) }
              </td>
            </tr>
          )*/
          }
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
  const { userRole } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    userRole,
    tasks: nonRootActionableTasksForAppeal(state, { appealId: ownProps.appealId }),
    allTasks: getAllTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(TaskSnapshot);
