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
  top: '30px',
  left: '49.5%',
  bottom: 0
});

const grayLineTimelineStyling = css(grayLineStyling, { left: '9%',
  marginLeft: '12px',
  top: '39px' });

const greyDotAndlineStyling = css({ top: '25px' });

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

class TaskRows extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      taskInstructionsIsVisibleObj: { }
    };
  }

  toggleTaskInstructionsVisibility = (task) => {
    let previousState = Object.assign({}, this.state.taskInstructionsIsVisibleObj);
    previousState[task.uniqueId] = previousState[task.uniqueId] ? !previousState[task.uniqueId] : true;
    this.setState({ taskInstructionsIsVisibleObj: previousState });
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
    if (task.completedOn) {
      return null;
    }

    return task.assignedOn ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={task.assignedOn} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  completedOnListItem = (task) => {
    return task.completedOn ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_COMPLETED_DATE_LABEL}</dt>
      <dd><DateString date={task.completedOn} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  dueDateListItem = (task) => {
    return task.dueOn ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={task.dueOn} dateFormat="MM/DD/YYYY" /></dd></div> : null;
  }

  daysWaitingListItem = (task) => {
    if (task.completedOn) {
      return null;
    }

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
    if (task.completedOn) {
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
      { this.state.taskInstructionsIsVisibleObj[task.uniqueId] &&
      <React.Fragment key={`${task.uniqueId}instructions_text`} >
        <dt>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
        <dd>{this.taskInstructionsWithLineBreaks(task)}</dd>
      </React.Fragment> }
      <Button
        linkStyling
        styling={css({ padding: '0' })}
        id={task.uniqueId}
        name={this.state.taskInstructionsIsVisibleObj[task.uniqueId] ? COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
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

  render = () => {
    const {
      appeal,
      taskList,
      timeline
    } = this.props;

    return <React.Fragment key={appeal.externalId}>
      { timeline && <tr>
        <td {...taskTimeTimelineContainerStyling}></td>
        <td {...taskInfoWithIconTimelineContainer} {...greyDotStyling}><GrayDot />
          { (taskList.length > 0 || (appeal.isLegacyAppeal && appeal.form9Date) || (appeal.nodDate)) &&
            <div {...grayLineTimelineStyling}{...css({ top: '25px !important' })} />}</td>
        <td {...taskInformationTimelineContainerStyling}>
          { appeal.decisionDate ? COPY.CASE_TIMELINE_DISPATCHED_FROM_BVA : COPY.CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING
          } <br />
        </td>
      </tr> }
      { taskList.map((task, index) =>
        <tr key={task.uniqueId}>
          <td {...taskTimeContainerStyling} className={timeline ? taskTimeTimelineContainerStyling : ''}>
            <CaseDetailsDescriptionList>
              { this.assignedOnListItem(task) }
              { this.completedOnListItem(task) }
              { this.dueDateListItem(task) }
              { !task.completedOn && this.daysWaitingListItem(task) }
            </CaseDetailsDescriptionList>
          </td>
          <td {...taskInfoWithIconContainer} className={[timeline ? taskInfoWithIconTimelineContainer : '',
            task.completedOn ? '' : greyDotTimelineStyling].join(' ')}>
            { task.completedOn && timeline ? <GreenCheckmark /> : <GrayDot /> }
            { (((index < taskList.length) && timeline) || (index < taskList.length - 1 && !timeline)) &&
              <div {...grayLineStyling} className={[timeline ? grayLineTimelineStyling : '',
                task.completedOn ? '' : greyDotAndlineStyling].join(' ')} /> }
          </td>
          <td {...taskInformationContainerStyling}
            className={timeline ? taskInformationTimelineContainerStyling : ''}>
            <CaseDetailsDescriptionList>
              { timeline && task.timelineTitle }
              { this.assignedToListItem(task) }
              { this.assignedByListItem(task) }
              { this.taskLabelListItem(task) }
              { this.taskInstructionsListItem(task) }
            </CaseDetailsDescriptionList>
          </td>
          { !timeline && <td {...taskActionsContainerStyling}>
            { this.showActionsListItem(task, appeal) } </td> }
        </tr>
      ) }
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

const mapStateToProps = () => {

  return {
  };
};

export default (withRouter(connect(mapStateToProps, null)(TaskRows)): React.ComponentType<>);
