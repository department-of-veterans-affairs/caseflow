import { css } from 'glamor';
import React from 'react';
import moment from 'moment';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import COPY from '../../../COPY';
import { GrayDot, GreenCheckmark, CancelIcon } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';
import { taskIsOnHold, sortCaseTimelineEvents } from '../utils';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import ActionsDropdown from '../components/ActionsDropdown';
import OnHoldLabel from '../components/OnHoldLabel';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import DecisionDateTimeLine from '../components/DecisionDateTimeLine';
import ReactMarkdown from 'react-markdown';
import { EditNodDateModalContainer } from './EditNodDateModal';
import { NodDateUpdateTimeline } from './NodDateUpdateTimeline';

export const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '30px',
  left: '45.5%',
  bottom: 0
});

export const grayLineTimelineStyling = css(grayLineStyling, { left: '9%',
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
const taskTimeTimelineContainerStyling = css(taskContainerStyling, { width: '40%' });
const taskInfoWithIconTimelineContainer =
  css(taskInfoWithIconContainer, { textAlign: 'left',
    marginLeft: '5px',
    width: '10%',
    paddingLeft: '0px' });

const isCancelled = (task) => {
  return task.status === TASK_STATUSES.cancelled;
};

const tdClassNames = (timeline, task) => {
  const containerClass = timeline ? taskInfoWithIconTimelineContainer : '';
  const closedAtClass = task.closedAt ? null : <span className="greyDotTimelineStyling"></span>;

  return [containerClass, closedAtClass].filter((val) => val).join(' ');
};

const cancelGrayTimeLineStyle = (timeline) => {
  return timeline ? grayLineTimelineStyling : '';
};

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
      taskInstructionsIsVisible: { },
      showEditNodDateModal: false,
      activeTasks: [...props.taskList]
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
      <dd>{moment(task.assignedOn).format('MM/DD/YYYY')}</dd></div> : null;
  }

  closedAtListItem = (task) => {
    return task.closedAt ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_COMPLETED_DATE_LABEL}</dt>
      <dd>{moment(task.closedAt).format('MM/DD/YYYY')}</dd></div> : null;
  }

  cancelledAtListItem = (task) => {
    return <div><dt>{COPY.TASK_SNAPSHOT_TASK_CANCELLED_DATE_LABEL}</dt>
      <dd>{moment(task.closedAt).format('MM/DD/YYYY')}</dd></div>;
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

    return assignor ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
      <dd>{assignor}</dd></div> : null;
  }

  cancelledByListItem = (task) => {
    const canceler = task.cancelledBy?.cssId;

    return canceler ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_CANCELER_LABEL}</dt>
      <dd>{canceler}</dd></div> : null;
  }

  cancelReasonListItem = (task) => {
    const reason = task.cancelReason;

    return reason ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_CANCEL_REASON_LABEL}</dt>
      <dd>{COPY.TASK_SNAPSHOT_CANCEL_REASONS[reason]}</dd></div> : null;
  }

  hearingRequestTypeConvertedBy = (task) => {
    const convertedBy = task.convertedBy?.cssId;

    return convertedBy ? <div><dt>{COPY.TASK_SNAPSHOT_HEARING_REQUEST_CONVERTER_LABEL}</dt>
      <dd>{convertedBy}</dd></div> : null;
  }

  taskLabelListItem = (task) => {
    if (task.closedAt) {
      return null;
    }

    return task.label ? <div><dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt>
      <dd>{task.label}</dd></div> : null;
  }

  taskInstructionsWithLineBreaks = (task) => {
    if (!task.instructions || !task.instructions.length) {
      return <br />;
    }

    // We aren't allowing ReactMarkdown to do full HTML parsing, so we'll convert any `<br>`
    // or newline characters to the Markdown standard of two spaces followed by \n
    const formatBreaks = (text = '') => {
      // Somehow the contents are occasionally an array, at least in tests
      // Here we'll format the individual items, then just join to ensure we return string
      if (Array.isArray(text)) {
        return text.map((item) => item.replace(/<br>|(?<! {2})\n/g, '  \n')).join(' ');
      }

      // Normally this should just be a string
      return text.replace(/<br>|(?<! {2})\n/g, '  \n');
    };

    // We specify the same 2.4rem margin-bottom as paragraphs to each set of instructions
    // to ensure a consistent margin between instruction content and the "Hide" button
    const divStyles = { marginBottom: '2.4rem' };

    return (
      <React.Fragment key={`${task.uniqueId} fragment`}>
        {task.instructions.map((text) => (
          <React.Fragment key={`${task.uniqueId} div`}>
            <div key={`${task.uniqueId} instructions`} style={divStyles} className="task-instructions">
              <ReactMarkdown>{formatBreaks(text)}</ReactMarkdown>
            </div>
          </React.Fragment>
        ))}
      </React.Fragment>
    );
  }

  taskInstructionsListItem = (task) => {
    if (!task.instructions || !task.instructions.length > 0) {
      return null;
    }

    return <div>
      { this.state.taskInstructionsIsVisible[task.uniqueId] &&
      <React.Fragment key={`${task.uniqueId}instructions_text`} >
        <dt style={{ width: '100%' }}>{COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
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

  hearingRequestTypeConvertedAtListItem = (task) => {
    return task.convertedOn ? <div><dt>{COPY.TASK_SNAPSHOT_HEARING_REQUEST_CONVERTED_ON_LABEL}</dt>
      <dd>{moment(task.convertedOn).format('MM/DD/YYYY')}</dd></div> : null;
  };

  closedOrCancelledAtListItem = (task) => {
    if (isCancelled(task)) {
      return this.cancelledAtListItem(task);
    }

    return task.type === 'ChangeHearingRequestTypeTask' ?
      this.hearingRequestTypeConvertedAtListItem(task) : this.closedAtListItem(task);

  }

  showTimelineDescriptionItems = (task, timeline) => {
    if (task.type === 'ChangeHearingRequestTypeTask' && timeline) {
      return this.hearingRequestTypeConvertedBy(task);
    }

    return (
      <React.Fragment>
        { this.assignedToListItem(task) }
        { this.assignedByListItem(task) }
        { this.cancelledByListItem(task) }
        { this.cancelReasonListItem(task) }
        { this.taskLabelListItem(task) }
        { this.taskInstructionsListItem(task) }
      </React.Fragment>
    );

  }

  taskTemplate = (templateConfig) => {
    const { task, sortedTimelineEvents, index, timeline, appeal } = templateConfig;

    const timelineTitle = isCancelled(task) ? `${task.type} cancelled` : task.timelineTitle;

    return <tr key={task.uniqueId}>
      <td {...taskTimeContainerStyling} className={timeline ? taskTimeTimelineContainerStyling : ''}>
        <CaseDetailsDescriptionList>
          { this.assignedOnListItem(task) }
          { this.closedOrCancelledAtListItem(task) }
          { !task.closedAt && this.daysWaitingListItem(task) }
        </CaseDetailsDescriptionList>
      </td>
      <td {...taskInfoWithIconContainer} className={tdClassNames(timeline, task)}>
        { isCancelled(task) ? <CancelIcon /> : closedAtIcon(task, timeline) }
        { (((index < sortedTimelineEvents.length) && timeline) ||
          (index < this.state.activeTasks.length - 1 && !timeline)) &&
              <div {...grayLineStyling} className={[cancelGrayTimeLineStyle(timeline),
                task.closedAt ? '' : greyDotAndlineStyling].join(' ')} /> }
      </td>
      <td {...taskInformationContainerStyling}
        className={timeline ? 'taskInformationTimelineContainerStyling' : ''}>
        <CaseDetailsDescriptionList>
          { timeline && timelineTitle }
          { this.showTimelineDescriptionItems(task, timeline) }
        </CaseDetailsDescriptionList>
      </td>
      { !timeline && <td className="taskContainerStyling taskActionsContainerStyling">
        { this.showActionsListItem(task, appeal) } </td> }
    </tr>;
  }

  toggleEditNodDateModal = () => this.setState((state) => ({ showEditNodDateModal: !state.showEditNodDateModal }));

  handleNODDateChange = () => {
    this.toggleEditNodDateModal();
  }

  render = () => {
    const {
      appeal,
      taskList,
      timeline
    } = this.props;
    const nodDateUpdates = appeal.nodDateUpdates;

    const sortedTimelineEvents = sortCaseTimelineEvents(taskList, nodDateUpdates);

    return <React.Fragment key={appeal.externalId}>

      { sortedTimelineEvents.map((timelineEvent, index) => {

        if (timelineEvent.isDecisionDate) {
          return <DecisionDateTimeLine
            appeal = {appeal}
            timeline = {timeline}
            taskList = {taskList} />;
        }

        if (timelineEvent.changeReason) {
          return <NodDateUpdateTimeline
            nodDateUpdate = {timelineEvent}
            timeline = {timeline}
          />;
        }

        const templateConfig = {
          task: timelineEvent,
          index,
          timeline,
          sortedTimelineEvents,
          appeal
        };

        return this.taskTemplate(templateConfig);
      }) }

      {/* Tasks and decision dates won't be in chronological order unless added to task list
          to return under render function*/}
      { timeline && appeal.isLegacyAppeal && <tr>
        <td className="taskContainerStyling taskTimeTimelineContainerStyling">
          { appeal.form9Date ? moment(appeal.form9Date).format('MM/DD/YYYY') : null }
        </td>
        <td {...taskInfoWithIconTimelineContainer} className={appeal.form9Date ? '' : 'greyDotStyling'}>
          { appeal.form9Date ? <GreenCheckmark /> : <GrayDot /> }
          { appeal.nodDate && <div className="grayLineStyling grayLineTimelineStyling" />}</td>
        <td className="taskContainerStyling taskInformationTimelineContainerStyling">
          { appeal.form9Date ? COPY.CASE_TIMELINE_FORM_9_RECEIVED : COPY.CASE_TIMELINE_FORM_9_PENDING}
        </td>
      </tr> }
      { timeline && appeal.nodDate && <tr>
        <td className="taskContainerStyling taskTimeTimelineContainerStyling">
          { moment(appeal.nodDate).format('MM/DD/YYYY') }
        </td>
        <td className="taskInfoWithIconContainer taskInfoWithIconTimelineContainer">
          <GreenCheckmark /></td>
        <td className="taskContainerStyling taskInformationTimelineContainerStyling">
          { COPY.CASE_TIMELINE_NOD_RECEIVED } <br />
          {this.props.editNodDateEnabled && (
            <React.Fragment>
              <p>
                <Button
                  type="button"
                  linkStyling
                  styling={css({ paddingLeft: '0' })}
                  onClick={this.toggleEditNodDateModal}>
                  {COPY.CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY}
                </Button>
              </p>
              {this.state.showEditNodDateModal && (
                <EditNodDateModalContainer
                  onCancel={this.toggleEditNodDateModal}
                  onSubmit={this.toggleEditNodDateModal}
                  nodDate={appeal.nodDate}
                  appealId={appeal.externalId}
                />
              )}
            </React.Fragment>
          )}
        </td>
      </tr> }
    </React.Fragment>;
  }
}

TaskRows.propTypes = {
  appeal: PropTypes.object,
  editNodDateEnabled: PropTypes.bool,
  hideDropdown: PropTypes.bool,
  taskList: PropTypes.array,
  timeline: PropTypes.bool
};

export default TaskRows;
