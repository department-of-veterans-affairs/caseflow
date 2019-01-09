import { css } from 'glamor';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';

import {
  appealWithDetailSelector,
  nonRootActionableTasksForAppeal
} from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import ActionsDropdown from './components/ActionsDropdown';
import OnHoldLabel from './components/OnHoldLabel';
import AddNewTaskButton from './components/AddNewTaskButton';

import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import { COLORS } from '../constants/AppConstants';
import StringUtil from '../util/StringUtil';

import { taskIsOnHold } from './utils';
import { DateString } from '../util/DateUtil';
import type { Appeal } from './types/models';
import type { State } from './types/state';

import { GrayDot } from '../components/RenderFunctions';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling
} from './StickyNavContentArea';
import Button from '../components/Button';

export const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '25px',
  left: '45%',
  bottom: 0
});

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

const taskInfoWithIconContainer = css({
  textAlign: 'center',
  border: 'none',
  padding: '0 10px 10px',
  position: 'relative',
  verticalAlign: 'top',
  width: '45px'
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
  constructor(props) {
    super(props);
    this.state = {
      taskInstructionsIsVisible: false
    };
  }

  toggleTaskInstructionsVisibility = () => {
    const prevState = this.state.taskInstructionsIsVisible;

    this.setState({ taskInstructionsIsVisible: !prevState });
  }

  daysSinceTaskAssignmentListItem = (task) => {
    if (task) {
      const today = moment().startOf('day');
      const dateAssigned = moment(task.assignedOn);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return <React.Fragment>
        <dt>{COPY.TASK_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt>
        <dd>{dayCountSinceAssignment}</dd>
      </React.Fragment>;
    }

    return null;
  };

  getAbbrevName = ({ firstName, lastName } : { firstName: string, lastName: string }) => {
    return `${firstName.substring(0, 1)}. ${lastName}`;
  }

  getActionName = (task) => {
    const {
      label
    } = task;

    // First see if there is a constant to convert the label, otherwise sentence-ify it
    if (CO_LOCATED_ADMIN_ACTIONS[label]) {
      return CO_LOCATED_ADMIN_ACTIONS[label];
    }

    return StringUtil.snakeCaseToSentence(label);
  }

  taskInstructionsWithLineBreaks = (instructions?: Array<string>) => {
    if (!instructions || !instructions.length) {
      return <br />;
    }

    return <React.Fragment>
      {instructions.map((text, i) => <React.Fragment><span key={i}>{text}</span><br /></React.Fragment>)}
    </React.Fragment>;
  }

  taskInstructionsListItem = (task) => {
    if (!task.instructions || !task.instructions.length > 0) {
      return null;
    }

    return <div>
      { this.state.taskInstructionsIsVisible &&
      <React.Fragment key={task.uniqueId} >
        <dt>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
        <dd>{this.taskInstructionsWithLineBreaks(task.instructions)}</dd>
      </React.Fragment> }
      <Button
        linkStyling
        styling={css({ padding: '0' })}
        name={this.state.taskInstructionsIsVisible ? COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
          COPY.TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL}
        onClick={this.toggleTaskInstructionsVisibility} />
    </div>;
  }

  assignedToListItem = (task) => {
    const assignee = task.isLegacy ? this.props.appeal.locationCode : task.assignedTo.cssId;

    return assignee ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt>
      <dd>{assignee}</dd></div> : null;
  }

  assignedByListItem = (task) => {
    const assignor = task.assignedBy.firstName ? this.getAbbrevName(task.assignedBy) : null;

    return assignor ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_FROM_LABEL}</dt>
      <dd>{assignor}</dd></div> : null;
  }

  taskLabelListItem = (task) => {
    return task.label ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt>
      <dd>{this.getActionName(task)}</dd></div> : null;
  }

  addedByNameListItem = (task) => {
    return task.addedByName ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
      <dd>{task.addedByName}</dd></div> : null;
  }

  assignedOnListItem = (task) => {
    return task.assignedOn ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={task.assignedOn} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  dueDateListItem = (task) => {
    return task.dueOn ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={task.dueOn} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  daysWaitingListItem = (task) => {
    return taskIsOnHold(task) ? <div><dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
      <dd><OnHoldLabel task={task} /></dd></div> : this.daysSinceTaskAssignmentListItem(task);
  }

  showActionsListItem = (task, appeal) => {
    return this.showActionsSection(task) ? <div><h3>{COPY.TASK_SNAPSHOT_ACTION_BOX_TITLE}</h3>
      <ActionsDropdown task={task} appealId={appeal.externalId} /></div> : null;
  }

  showActionsSection = (task) => (task && !this.props.hideDropdown);

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
          { tasks.map((task, index) =>
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
          )
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
    tasks: nonRootActionableTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(TaskSnapshot);
