import { css } from 'glamor';
import React from 'react';
import moment from 'moment';
import Button from '../../components/Button';
import COPY from '../../../COPY.json';
import { DateString } from '../../util/DateUtil';
import { GrayDot, GreenCheckmark, CancelIcon } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';
import { taskIsOnHold, sortTaskList } from '../utils';
import StringUtil from '../../util/StringUtil';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import ActionsDropdown from '../components/ActionsDropdown';
import OnHoldLabel from '../components/OnHoldLabel';
import TASK_STATUSES from '../../../constants/TASK_STATUSES.json';

export const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '30px',
  left: '49.5%',
  bottom: 0
});

const grayLineTimelineStyling = css(grayLineStyling, { left: '9%',
  marginLeft: '12px',
  top: '39px' });

const greyDotAndlineStyling = css({ top: '25px' });

const closedAtIcon = (task, timeline) => {
  return (task.closedAt && timeline ? <GreenCheckmark /> : <GrayDot />);
};

const taskContainerStyling = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px',
  paddingBottom: '3rem'
});

const taskInfoWithIconContainer = css({
  textAlign: 'center',
  border: 'none',
  padding: '0 0 0 0',
  position: 'relative',
  verticalAlign: 'top',
  width: '15px'
});

const taskTimeContainerStyling = css(taskContainerStyling, { width: '20%' });
const taskInformationContainerStyling = css(taskContainerStyling, { width: '25%' });
const taskActionsContainerStyling = css(taskContainerStyling, { width: '50%' });
const taskTimeTimelineContainerStyling = css(taskContainerStyling, { width: '40%' });
const taskInformationTimelineContainerStyling =
  css(taskInformationContainerStyling, { align: 'left',
    width: '50%',
    maxWidth: '235px' });

const taskInfoWithIconTimelineContainer =
  css(taskInfoWithIconContainer, { textAlign: 'left',
    marginLeft: '5px',
    width: '10%',
    paddingLeft: '0px' });

const greyDotStyling = css({ paddingLeft: '6px' });
const greyDotTimelineStyling = css({ padding: '0px 0px 0px 5px' });
const isCancelled = (task) => {
  return task.status === TASK_STATUSES.cancelled;
};

const tdClassNames = (timeline, task) => {
  const containerClass = timeline ? taskInfoWithIconTimelineContainer : '';
  const closedAtClass = task.closedAt ? null : greyDotTimelineStyling;

  return [containerClass, closedAtClass].filter((val) => val).join(' ');
};

const cancelGrayTimeLineStyle = (timeline) => {
  return timeline ? grayLineTimelineStyling : '';
};

const timelineLeftPaddingStyle = css({ paddingLeft: '0px' });

class TaskRows extends React.PureComponent {
  constructor(props) {
    super(props);

    const mappedDecisionDateObj = this.mapDecisionDateToSortableObject(this.props.appeal);

    if (this.props.appeal.decisionDate) {
      this.props.taskList.push(mappedDecisionDateObj);
    } else {
      this.props.taskList.unshift(mappedDecisionDateObj);
    }

    this.state = {
      taskInstructionsIsVisible: { }
    };
  }

  toggleTaskInstructionsVisibility = (task) => {
    const previousState = Object.assign({}, this.state.taskInstructionsIsVisible);

    previousState[task.uniqueId] = previousState[task.uniqueId] ? !previousState[task.uniqueId] : true;
    this.setState({ taskInstructionsIsVisible: previousState });
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
    if (task.closedAt) {
      return null;
    }

    return task.assignedOn ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={task.assignedOn} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  closedAtListItem = (task) => {
    return task.closedAt ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_COMPLETED_DATE_LABEL}</dt>
      <dd><DateString date={task.closedAt} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  cancelledAtListItem = (task) => {
    return <div><dt>{COPY.TASK_SNAPSHOT_TASK_CANCELLED_DATE_LABEL}</dt>
      <dd><DateString date={task.closedAt} dateFormat="MM/DD/YYYY" /></dd></div>;
  }

  showWithdrawalDate = () => {
    return this.props.appeal.withdrawalDate ? <div>
      <dt>{COPY.TASK_SNAPSHOT_TASK_WITHDRAWAL_DATE_LABEL}</dt>
      <dd><DateString date={this.props.appeal.withdrawalDate} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  showDecisionDate = () => {
    return this.props.appeal.decisionDate ? <div>
      <dd><DateString date={this.props.appeal.decisionDate} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  daysWaitingListItem = (task) => {
    if (task.closedAt) {
      return null;
    }

    return taskIsOnHold(task) ? <div><dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
      <dd><OnHoldLabel task={task} /></dd></div> : this.daysSinceTaskAssignmentListItem(task);
  }

  assignedToListItem = (task) => {
    const assignee = task.assigneeName;

    return assignee ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt>
      <dd>{assignee}</dd></div> : null;
  }

  getAbbrevName = ({ firstName, lastName }) => `${firstName.substring(0, 1)}. ${lastName}`;

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
    if (task.closedAt) {
      return null;
    }

    return task.label ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt>
      <dd>{this.getActionName(task)}</dd></div> : null;
  }

  taskInstructionsWithLineBreaks = (task) => {
    if (!task.instructions || !task.instructions.length) {
      return <br />;
    }

    return <React.Fragment key={`${task.uniqueId} fragment`}>
      {task.instructions.map((text) => <React.Fragment key={`${task.uniqueId} span`}>
        <span key={`${task.uniqueId} instructions`}>{text}</span><br /></React.Fragment>)}
    </React.Fragment>;
  }

  taskInstructionsListItem = (task) => {
    if (!task.instructions || !task.instructions.length > 0) {
      return null;
    }

    return <div>
      { this.state.taskInstructionsIsVisible[task.uniqueId] &&
      <React.Fragment key={`${task.uniqueId}instructions_text`} >
        <dt>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
        <dd>{this.taskInstructionsWithLineBreaks(task)}</dd>
      </React.Fragment> }
      <Button
        linkStyling
        styling={css({ padding: '0' })}
        id={task.uniqueId}
        name={this.state.taskInstructionsIsVisible[task.uniqueId] ? COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
          COPY.TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL}
        onClick={() => this.toggleTaskInstructionsVisibility(task)} />
    </div>;
  }

  showActionsListItem = (task, appeal) => {
    if (task.availableActions.length <= 0) {
      return null;
    }

    return this.showActionsSection(task) ? <div><h3>{COPY.TASK_SNAPSHOT_ACTION_BOX_TITLE}</h3>
      <ActionsDropdown task={task} appealId={appeal.externalId} /></div> : null;
  }

  showActionsSection = (task) => (task && !this.props.hideDropdown);

  mapDecisionDateToSortableObject = (appeal) => {
    // if there's no decision date, then this object should be at the top 
    // of the case timeline, thus the negative infinity default 
    return {
      isDecisionDate: true,
      createdAt: appeal.decisionDate || Number.NEGATIVE_INFINITY
    };
  }

  taskTemplate = (templateConfig) => {
    const { task, taskList, index, timeline, appeal } = templateConfig;

    const timelineTitle = isCancelled(task) ? `${task.type} cancelled` : task.timelineTitle;

    return <tr key={task.uniqueId}>
      <td {...taskTimeContainerStyling} className={timeline ? taskTimeTimelineContainerStyling : ''}>
        <CaseDetailsDescriptionList>
          { this.assignedOnListItem(task) }
          { isCancelled(task) ? this.cancelledAtListItem(task) : this.closedAtListItem(task) }
          { !task.closedAt && this.daysWaitingListItem(task) }
        </CaseDetailsDescriptionList>
      </td>
      <td {...taskInfoWithIconContainer} className={tdClassNames(timeline, task)}>
        { isCancelled(task) ? <CancelIcon /> : closedAtIcon(task, timeline) }
        { (((index < taskList.length) && timeline) || (index < taskList.length - 1 && !timeline)) &&
              <div {...grayLineStyling} className={[cancelGrayTimeLineStyle(timeline),
                task.closedAt ? '' : greyDotAndlineStyling].join(' ')} /> }
      </td>
      <td {...taskInformationContainerStyling}
        className={timeline ? taskInformationTimelineContainerStyling : ''}>
        <CaseDetailsDescriptionList>
          { timeline && timelineTitle }
          { this.assignedToListItem(task) }
          { this.assignedByListItem(task) }
          { this.taskLabelListItem(task) }
          { this.taskInstructionsListItem(task) }
        </CaseDetailsDescriptionList>
      </td>
      { !timeline && <td {...taskActionsContainerStyling}>
        { this.showActionsListItem(task, appeal) } </td> }
    </tr>;
  }

  decisionDateTemplate = (templateConfig) => {
    const { taskList, timeline, appeal } = templateConfig;
    let timelineContainerText;
    let timeLineIcon;
    let grayLineIconStyling;

    if (appeal.withdrawn) {
      timelineContainerText = COPY.CASE_TIMELINE_APPEAL_WITHDRAWN;
      timeLineIcon = <CancelIcon />;
      grayLineIconStyling = grayLineTimelineStyling;
    } else if (appeal.decisionDate) {
      timelineContainerText = COPY.CASE_TIMELINE_DISPATCHED_FROM_BVA;
      timeLineIcon = <GreenCheckmark />;
    } else {
      timelineContainerText = COPY.CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING;
      timeLineIcon = <GrayDot />;
      grayLineIconStyling = css({ top: '25px !important' });
    }

    if (timeline) {
      return <tr>
        <td {...taskTimeTimelineContainerStyling}>
          <CaseDetailsDescriptionList>
            { appeal.decisionDate ? this.showDecisionDate() : this.showWithdrawalDate() }
          </CaseDetailsDescriptionList>
        </td>
        <td {...taskInfoWithIconTimelineContainer}
          {...(appeal.withdrawalDate || appeal.decisionDate ? timelineLeftPaddingStyle : greyDotTimelineStyling)}>
          {timeLineIcon}
          { (taskList.length > 0 || (appeal.isLegacyAppeal && appeal.form9Date) || (appeal.nodDate)) &&
          <div {...grayLineTimelineStyling}
            {...grayLineIconStyling} />}
        </td>
        <td {...taskInformationTimelineContainerStyling}>
          { timelineContainerText } <br />
        </td>
      </tr>;
    }
  }

  render = () => {
    const {
      appeal,
      taskList,
      timeline
    } = this.props;

    return <React.Fragment key={appeal.externalId}>

      { sortTaskList(taskList, appeal).map((task, index) => {
        const templateConfig = {
          task,
          index,
          timeline,
          taskList,
          appeal
        };

        if (!task.isDecisionDate) {
          return this.taskTemplate(templateConfig);
        }

        return this.decisionDateTemplate(templateConfig);

      }) }
      {/* everything below here will not be in chronological order unless it's added to the task list on line 287*/}
      { timeline && appeal.isLegacyAppeal && <tr>
        <td {...taskTimeTimelineContainerStyling}>
          { appeal.form9Date ? moment(appeal.form9Date).format('MM/DD/YYYY') : null }
        </td>
        <td {...taskInfoWithIconTimelineContainer} className={appeal.form9Date ? '' : greyDotStyling}>
          { appeal.form9Date ? <GreenCheckmark /> : <GrayDot /> }
          { appeal.nodDate && <div {...grayLineTimelineStyling} />}</td>
        <td {...taskInformationTimelineContainerStyling}>
          { appeal.form9Date ? COPY.CASE_TIMELINE_FORM_9_RECEIVED : COPY.CASE_TIMELINE_FORM_9_PENDING}
        </td>
      </tr> }
      { timeline && appeal.nodDate && <tr>
        <td {...taskTimeTimelineContainerStyling}>
          { moment(appeal.nodDate).format('MM/DD/YYYY') }
        </td>
        <td {...taskInfoWithIconTimelineContainer}>
          { <GreenCheckmark /> } </td>
        <td {...taskInformationTimelineContainerStyling}>
          { COPY.CASE_TIMELINE_NOD_RECEIVED } <br />
        </td>
      </tr> }
    </React.Fragment>;
  }
}

export default TaskRows;
