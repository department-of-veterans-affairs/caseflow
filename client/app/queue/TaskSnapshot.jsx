import { css } from 'glamor';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';

import {
  actionableTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import ActionsDropdown from './components/ActionsDropdown';
import OnHoldLabel from './components/OnHoldLabel';

import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import { COLORS } from '../constants/AppConstants';
import StringUtil from '../util/StringUtil';

import { taskIsOnHold } from './utils';
import { DateString } from '../util/DateUtil';
import type { Appeal, Task } from './types/models';
import type { State } from './types/state';

import { GrayDot } from '../components/RenderFunctions';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling
} from './StickyNavContentArea';

export const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '20px',
  left: '45%',
  bottom: 0
});

const lastTask = css({
  bottom: '150px',
  marginBottom: '150px'
});

const taskContainerStyling = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px'
});

const taskTimeContainerStyling = css(taskContainerStyling, { width: '20%' });
const taskInformationContainerStyling = css(taskContainerStyling, { width: '25%' });

const taskInfoWithIconContainer = css({
  textAlign: 'center',
  border: 'none',
  padding: '0px',
  position: 'relative',
  verticalAlign: 'top',
  width: '45px'
});

const titleLabel = css({
  fontWeight: 'bold'
});

type Params = {|
  appealId: string,
  hideDropdown?: boolean
|};

type Props = Params & {|
  userRole: string,
  appeal: Appeal,
  primaryTask: Task,
|};

export class TaskSnapshot extends React.PureComponent<Props> {
  daysSinceTaskAssignmentListItem = (task) => {
    if (task) {
      const today = moment().startOf('day');
      const dateAssigned = moment(task.assignedOn);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return <React.Fragment>
        <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt>
        <dd>{dayCountSinceAssignment}</dd>
      </React.Fragment>;
    }

    return null;
  };

  getAbbrevName = ({ firstName, lastName } : { firstName: string, lastName: string }) => {
    return `${firstName.substring(0, 1)}. ${lastName}`;
  }

  getActionName = () => {
    const {
      label
    } = this.props.primaryTask;

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

  taskInformation = (task) => {
    if (!task) {
      return null;
    }

    const assignedByAbbrev = task.assignedBy.firstName ?
      this.getAbbrevName(task.assignedBy) : null;

    const preparedByAbbrev = task.decisionPreparedBy ?
      this.getAbbrevName(task.decisionPreparedBy) : null;

    return <React.Fragment>
      <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{task.assignedTo.cssId}</dd>
      { assignedByAbbrev &&
        <React.Fragment>
          <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment> }
      { preparedByAbbrev &&
        <React.Fragment>
          <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{preparedByAbbrev}</dd>
        </React.Fragment> }
      { task.label &&
        <React.Fragment>
          <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{this.getActionName()}</dd>
        </React.Fragment> }
      { taskIsOnHold(task) &&
        <React.Fragment>
          <dt {...titleLabel}>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
          <dd><OnHoldLabel task={task} /></dd>
        </React.Fragment>
      }
      { task.instructions &&
        <React.Fragment>
          <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(task.instructions)}</dd>
        </React.Fragment> }
    </React.Fragment>;
  }

  legacyTaskInformation = (task) => {
    console.log('-----------**-----------')

    // If this is not a task attached to a legacy appeal, use taskInformation.
    if (!this.props.appeal.isLegacyAppeal) {
      return this.taskInformation(task);
    }
    console.log('----------- -1-----------')


    const {
      userRole
    } = this.props;

    if (!task) {
      console.log('-----------0-----------')
      return null;
    }
    console.log('-----------1-----------')

    const assignedByAbbrev = task.assignedBy.firstName ?
      this.getAbbrevName(task.assignedBy) : null;
    console.log(assignedByAbbrev)
    console.log(userRole)
    console.log(this.props.appeal.locationCode)

    const assignedToListItem = <React.Fragment>
      <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.locationCode}</dd>
    </React.Fragment>;

    console.log('-----------2-----------')

    if ([USER_ROLE_TYPES.judge, USER_ROLE_TYPES.colocated].includes(userRole)) {
      const assignedByFirstName = task.assignedBy.firstName;
      const assignedByLastName = task.assignedBy.lastName;
      console.log(assignedByFirstName)
      console.log(assignedByLastName)
      console.log(assignedToListItem)

      console.log('-----------3-----------')

      if (!assignedByFirstName ||
          !assignedByLastName ||
          (userRole === USER_ROLE_TYPES.judge && !task.documentId)) {
        return assignedToListItem;
      }

      console.log('-----------4-----------')


      if (userRole === USER_ROLE_TYPES.judge) {
        return <React.Fragment>
          <dt>{COPY.TASK_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment>;
        console.log('-----------5-----------')

      } else if (userRole === USER_ROLE_TYPES.colocated) {
        console.log('-----------6-----------')

        return <React.Fragment>
          <dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{CO_LOCATED_ADMIN_ACTIONS[task.label]}</dd>
          <dt>{COPY.TASK_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
          { taskIsOnHold(task) &&
            <React.Fragment>
              <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
              <dd><OnHoldLabel task={task} /></dd>
            </React.Fragment>
          }
          <dt>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(task.instructions)}</dd>
        </React.Fragment>;
      }
      console.log('-----------7-----------')

    }

    return <React.Fragment>
      { task.addedByName && <React.Fragment>
        <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{task.addedByName}</dd>
      </React.Fragment> }
      <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={task.assignedOn} dateFormat="MM/DD/YY" /></dd>
      <dt>{COPY.TASK_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={task.dueOn} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  showActionsSection = (task): boolean => {
    if (this.props.hideDropdown) {
      return false;
    }

    const {
      userRole
    } = this.props;

    if (!task) {
      return false;
    }

    // users can end up at case details for appeals with no DAS
    // record (!task.taskId). prevent starting attorney checkout flows
    return userRole === USER_ROLE_TYPES.judge ? Boolean(task) : Boolean(task.taskId);
  }

  render = () => {
    const {
      appeal,
      primaryTask
    } = this.props;
    const taskAssignedToVso = primaryTask && primaryTask.assignedTo.type === 'Vso';

    let sectionBody = COPY.TASK_SNAPSHOT_NO_ACTIVE_LABEL;
    let tsk_length = this.props.tasks.length;

    if (this.props.primaryTask) {
      sectionBody = []
      { this.props.tasks.map((task, index) => (
        console.log(task),
        sectionBody.push(<table {...css({ width: '100%',
          marginTop: '0px', marginBottom: '5px'})}>
          <tbody>
            <tr>
              <td {...taskTimeContainerStyling}>
                <CaseDetailsDescriptionList>
                  <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
                  <dd>{task && task.assignedOn &&
                      moment(task.assignedOn).format('MM/DD/YYYY')}</dd>
                  {this.daysSinceTaskAssignmentListItem(task)}
                  {task.uniqueId}
                </CaseDetailsDescriptionList>
              </td>
              <td {...taskInfoWithIconContainer}><GrayDot /><div {...grayLineStyling} className={tsk_length-1 === index ? lastTask : ''} /></td>
              <td {...taskInformationContainerStyling}>
                <CaseDetailsDescriptionList>
                  { !taskAssignedToVso && appeal.assignedJudge &&
                    <React.Fragment>
                      <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_ASSIGNED_JUDGE_LABEL}</dt>
                      <dd>{appeal.assignedJudge.full_name}</dd>
                    </React.Fragment> }
                  { !taskAssignedToVso && appeal.assignedAttorney &&
                    <React.Fragment>
                      <dt {...titleLabel}>{COPY.TASK_SNAPSHOT_ASSIGNED_ATTORNEY_LABEL}</dt>
                      <dd>{appeal.assignedAttorney.full_name}</dd>
                    </React.Fragment> }
                  {this.legacyTaskInformation(task)}
                </CaseDetailsDescriptionList>
              </td>
              <td {...taskInformationContainerStyling} {...css({ width: '50%' })}>
                {this.showActionsSection(task) &&
                  <React.Fragment>
                    <h3>{COPY.TASK_SNAPSHOT_ACTION_BOX_TITLE}</h3>
                    <ActionsDropdown task={task} appealId={appeal.externalId} />
                  </React.Fragment>
                }
              </td>
            </tr>
          </tbody>
        </table>)
      ))}
    }

    return <div className="usa-grid" {...css({ marginTop: '3rem' })}>
      <h2 {...sectionHeadingStyling}>
        <a id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.TASK_SNAPSHOT_ACTIVE_TASKS_LABEL}</a>
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
    primaryTask: actionableTasksForAppeal(state, { appealId: ownProps.appealId })[0],
    tasks: actionableTasksForAppeal(state, { appealId: ownProps.appealId })
  };
};

export default connect(mapStateToProps)(TaskSnapshot);
