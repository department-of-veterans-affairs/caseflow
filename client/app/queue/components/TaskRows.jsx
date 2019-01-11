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
import { taskIsOnHold } from '../utils';
import StringUtil from '../../util/StringUtil';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import ActionsDropdown from '../components/ActionsDropdown';
import OnHoldLabel from '../components/OnHoldLabel';

export const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '39px',
  left: '49.5%',
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

const taskInfoWithIconContainer = css({
  textAlign: 'center',
  border: 'none',
  padding: '0 10px 10px',
  position: 'relative',
  verticalAlign: 'top',
  width: '45px'
});

class TaskRows extends React.PureComponent {
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

  taskInstructionsWithLineBreaks = (task) => {
    if (!task.instructions || !task.instructions.length) {
      return <br />;
    }

    return <React.Fragment key={`${task.uniqueId}fragment`}>
      {task.instructions.map((text) => <React.Fragment key={`${task.uniqueId}span`}>
        <span key={`${task.uniqueId}instructions`}>{text}</span><br /></React.Fragment>)}
    </React.Fragment>;
  }

  taskInstructionsListItem = (task) => {
    if (!task.instructions || !task.instructions.length > 0) {
      return null;
    }

    return <div>
      { this.state.taskInstructionsIsVisible &&
      <React.Fragment key={`${task.uniqueId}instructions_text`} >
        <dt>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
        <dd>{this.taskInstructionsWithLineBreaks(task)}</dd>
      </React.Fragment> }
      <Button
        linkStyling
        styling={css({ padding: '0' })}
        id={task.uniqueId}
        name={this.state.taskInstructionsIsVisible ? COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
          COPY.TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL}
        onClick={this.toggleTaskInstructionsVisibility} />
    </div>;
  }

  showActionsListItem = (task, appeal) => {
    return this.showActionsSection(task) ? <div><h3>{COPY.TASK_SNAPSHOT_ACTION_BOX_TITLE}</h3>
      <ActionsDropdown task={task} appealId={appeal.externalId} /></div> : null;
  }

  showActionsSection = (task) => (task && !this.props.hideDropdown);

  getTitle = (task) => {
    let title = '';

    if (task.type === 'AttorneyTask') {
      title = COPY.CASE_TIMELINE_ATTORNEY_TASK;
    } else if (task.type === 'JudgeTask') {
      title = COPY.CASE_TIMELINE_JUDGE_TASK;
    }

    return title;
  }

  render = () => {
    const {
      appeal,
      taskList,
      timeline
    } = this.props;

    return <React.Fragment key={appeal.externalId}>
      { timeline && <tr>
        <td {...taskTimeContainerStyling}></td>
        <td {...taskInfoWithIconContainer}><GrayDot /><div {...grayLineStyling} {...css({ top: '25px' })} /></td>
        <td {...taskInformationContainerStyling}>
          { appeal.decisionDate ? COPY.CASE_TIMELINE_DISPATCHED_FROM_BVA : COPY.CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING
          } <br />
        </td>
      </tr> }
      { taskList.map((task, index) =>
        <tr key={task.uniqueId}>
          <td {...taskTimeContainerStyling}>
            <CaseDetailsDescriptionList>
              { this.assignedOnListItem(task) }
              { this.dueDateListItem(task) }
              { this.daysWaitingListItem(task) }
            </CaseDetailsDescriptionList>
          </td>
          <td {...taskInfoWithIconContainer}>{ task.completedOn ? <GreenCheckmark /> : <GrayDot /> }
            { (index < taskList.length) && taskList[0].completedOn && <div {...grayLineStyling} /> }
          </td>
          <td {...taskInformationContainerStyling}>
            <CaseDetailsDescriptionList>
              { timeline && this.getTitle(task) }
              { this.assignedToListItem(task) }
              { this.assignedByListItem(task) }
              { this.taskLabelListItem(task) }
              { this.taskInstructionsListItem(task) }
            </CaseDetailsDescriptionList>
          </td>
          { !timeline && <td {...taskActionsContainerStyling}>
            { this.showActionsListItem(task, appeal) }
          </td> }
        </tr>
      ) }
      { timeline && appeal.isLegacyAppeal && <tr>
        <td {...taskTimeContainerStyling}>
          { appeal.form9Date ? moment(appeal.form9Date).format('MM/DD/YYYY') : null }
        </td>
        <td {...taskInfoWithIconContainer}>{ appeal.form9Date ? <GreenCheckmark /> : <GrayDot /> }
          <div {...grayLineStyling} /></td>
        <td {...taskInformationContainerStyling}>
          { appeal.form9Date ? COPY.CASE_TIMELINE_FORM_9_RECEIVED : COPY.CASE_TIMELINE_FORM_9_PENDING}
        </td>
      </tr> }
      { timeline && <tr>
        <td {...taskTimeContainerStyling}>
          { appeal.receiptDate ? moment(appeal.receiptDate).format('MM/DD/YYYY') : null }
        </td>
        <td {...taskInfoWithIconContainer}>{ appeal.receiptDate ? <GreenCheckmark /> : <GrayDot /> } </td>
        <td {...taskInformationContainerStyling}>
          { appeal.receiptDate ? COPY.CASE_TIMELINE_NOD_RECEIVED : COPY.CASE_TIMELINE_NOD_PENDING } <br />
        </td>
      </tr> }
    </React.Fragment>;
  }
}

const mapStateToProps = () => {

  return {
  };
};

export default (withRouter(connect(mapStateToProps, null)(TaskRows)): React.ComponentType<>);
