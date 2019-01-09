import { css } from 'glamor';
import React from 'react';
import moment from 'moment';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Button from '../../components/Button';
import COPY from '../../../COPY.json';
import { DateString } from '../../util/DateUtil';
import { GrayDot, GreenCheckmark } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';
import type { State } from '../types/state';
import { taskIsOnHold } from '../utils';
import { rootTasksForAppeal } from '../selectors';
import StringUtil from '../../util/StringUtil';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

export const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '25px',
  left: '45%',
  bottom: 0
});

const buttonStyling = css({
  float: 'right',
  paddingRight: '10px'
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

const taskInfoWithIconContainer = css({
  textAlign: 'center',
  border: 'none',
  padding: '0 10px 10px',
  position: 'relative',
  verticalAlign: 'top',
  width: '45px'
});

type Params = {|
  appealId: string
|};

class TaskRows extends React.PureComponent {

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

  assignedToListItem = (task) => {
    const assignee = task.isLegacy ? this.props.appeal.locationCode : task.assignedTo.cssId;

    return assignee ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt>
      <dd>{assignee}</dd></div> : null;
  }

  getAbbrevName = ({ firstName, lastName } : { firstName: string, lastName: string }) => {
    return `${firstName.substring(0, 1)}. ${lastName}`;
  }

  assignedByListItem = (task) => {
    const assignor = task.assignedBy.firstName ? this.getAbbrevName(task.assignedBy) : null;

    return assignor ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_FROM_LABEL}</dt>
      <dd>{assignor}</dd></div> : null;
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

  taskLabelListItem = (task) => {
    return task.label ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt>
      <dd>{this.getActionName(task)}</dd></div> : null;
  }

  render = () => {
    const {
      taskList
    } = this.props;

    console.log('------');
    console.log(taskList);

    return taskList.map((task, index) =>
      <tr key={task.uniqueId}>
        <td {...taskTimeContainerStyling}>
          <CaseDetailsDescriptionList>
            { this.assignedOnListItem(task) }
            { this.dueDateListItem(task) }
            { this.daysWaitingListItem(task) }
          </CaseDetailsDescriptionList>
        </td>
        <td {...taskInfoWithIconContainer}>{ task.completedOn ? <GreenCheckmark /> : <GrayDot /> }
          { (index + 1 < taskList.length) && <div {...grayLineStyling} /> }
        </td>
        <td {...taskInformationContainerStyling}>
          <CaseDetailsDescriptionList>
            { this.assignedToListItem(task) }
            { this.assignedByListItem(task) }
            { this.taskLabelListItem(task) }
            { /*this.taskInstructionsListItem(task)*/ }
          </CaseDetailsDescriptionList>
        </td>
        <td {...taskActionsContainerStyling}>
          { /*this.showActionsListItem(task, appeal)*/ }
        </td>
      </tr>
    )
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {

  return {
    rootTask: rootTasksForAppeal(state, { appealId: ownProps.appealId })[0]
  };
};

export default (withRouter(connect(mapStateToProps, null)(TaskRows)): React.ComponentType<>);
