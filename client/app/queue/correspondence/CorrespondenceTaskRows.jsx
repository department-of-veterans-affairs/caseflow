import React from 'react';
import { connect } from 'react-redux';
import moment from 'moment';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import COPY from '../../../COPY';
import { CancelIcon } from '../../components/icons/CancelIcon';
import { GrayDotIcon } from '../../components/icons/GrayDotIcon';
import { GreenCheckmarkIcon } from '../../components/icons/GreenCheckmarkIcon';
import { sortCaseTimelineEvents } from '../utils';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import ActionsDropdown from '../components/ActionsDropdown';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';

const closedAtIcon = (task, timeline) => {
  return task.closedAt && timeline ? <GreenCheckmarkIcon /> : <GrayDotIcon size={25} />;
};

const isCancelled = (task) => {
  return task.status === TASK_STATUSES.cancelled;
};

const establishmentTaskCorrespondence = (task) => {
  return task.type === 'EstablishmentTask';
};

// Update function to use class names as strings
const tdClassNamesforCorrespondence = (timeline, task) => {
  const closedAtClass = task.closedAt ? '' : 'greyDotAndlineStyling';
  const containerClass = timeline ? 'taskInfoWithIconTimelineContainer' : 'taskInfoWithIconContainer';

  return [containerClass, closedAtClass].filter(Boolean).join(' ');
};

const cancelGrayTimeLineStyle = (timeline) => {
  return timeline ? 'grayLineTimelineStyling' : 'grayLineStyling';
};

class CorrespondenceTaskRows extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      taskInstructionsIsVisible: [],
      showEditNodDateModal: false,
      activeTasks: props.taskList,
    };
  }

  toggleTaskInstructionsVisibility = (taskKey) => {
    const { taskInstructionsIsVisible } = this.state;

    if (taskInstructionsIsVisible.includes(taskKey)) {
      this.setState({
        taskInstructionsIsVisible: taskInstructionsIsVisible.filter(
          (key) => key !== taskKey
        ),
      });
    } else {
      this.setState({
        taskInstructionsIsVisible: [...taskInstructionsIsVisible, taskKey],
      });
    }
  };

  assignedOnListItem = (task) => {
    return task.assignedOn ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
        <dd>{moment(task.assignedOn).format('MM/DD/YYYY')}</dd>
      </div>
    ) : null;
  };

  assignedToListItem = (task) => {
    return (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt>
        <dd>{task.assignedTo}</dd>
      </div>
    );
  };

  taskLabelListItem = (task) => {
    if (task.closedAt) {
      return null;
    }

    return task.label ? (
      <div className="cf-row-wrapper">
        <dt>{COPY.TASK_SNAPSHOT_TASK_TYPE_LABEL}</dt>
        <dd>{task.label}</dd>
      </div>
    ) : null;
  };

  taskInstructionsWithLineBreaks = (task) => {
    if (!task.instructions || !task.instructions?.length) {
      return <br />;
    }

    return (
      <React.Fragment key={`${task.uniqueId} + ${task.instructions} fragment`}>
        {task.instructions.map((text) => (
          <div
            key={`${task.uniqueId} instructions`}
            className="task-instructions">
            <p>{text}</p>
          </div>
        ))}
      </React.Fragment>
    );
  };

  taskInstructionsListItem = (task) => {
    if (!task.instructions || !task.instructions?.length > 0) {
      return null;
    }

    const taskInstructionsVisible = this.state.taskInstructionsIsVisible.includes(task.label);

    return (
      <div className="cf-row-wrapper">
        {taskInstructionsVisible && (
          <React.Fragment key={`${task.assignedOn}${task.label}`}>
            {!establishmentTaskCorrespondence(task) && (
              <dt>
                {COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}
              </dt>
            )}
            <dd>
              {this.taskInstructionsWithLineBreaks(task)}

            </dd>
          </React.Fragment>
        )}
        <Button
          linkStyling
          id={task.uniqueId}
          name={
            taskInstructionsVisible ?
              COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
              COPY.TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
          }
          onClick={() => this.toggleTaskInstructionsVisibility(task.label)}
          classNames={['button-left-aligned']}
        />
      </div>
    );
  };

  showActionsListItem = (task, correspondence) => {
    if (task.availableActions?.length === 0) {
      return null;
    }

    return this.showActionsSection(task) ? (
      <div className="correspondence-task-actions-row-wrapper">
        <h3>{COPY.TASK_SNAPSHOT_ACTION_BOX_TITLE}</h3>
        <ActionsDropdown
          task={task}
          appealId={correspondence.uuid}
          type={correspondence.type}
        />
      </div>
    ) : null;
  };

  showActionsSection = (task) => task && !this.props.hideDropdown;

  showTimelineDescriptionItems = (task) => {
    return (
      <React.Fragment>
        {task.type !== 'IssuesUpdateTask' && this.assignedToListItem(task)}
        {this.taskLabelListItem(task)}
        {this.taskInstructionsListItem(task)}
      </React.Fragment>
    );
  };

  taskTemplate = (templateConfig) => {
    const {
      task,
      sortedTimelineEvents,
      index,
      timeline,
      correspondence
    } = templateConfig;

    const timelineTitle = isCancelled(task) ? `${task.type} cancelled` : task.timelineTitle;

    return (
      <tr key={task.uniqueId + task.instructions}>
        <td
          className={timeline ? 'taskTimeTimelineContainerStyling' : 'taskTimeContainerStyling'}
          role="cell"
        >
          <CaseDetailsDescriptionList>
            <div aria-label={`Task assigned on ${moment(task.assignedOn).format('MMMM DD, YYYY')}`}>
              {this.assignedOnListItem(task)}
            </div>
          </CaseDetailsDescriptionList>
        </td>
        <td className={tdClassNamesforCorrespondence(timeline, task)}>
          {isCancelled(task) ? <CancelIcon /> : closedAtIcon(task, timeline)}

          {/* Render grey line between tasks */}
          {index < sortedTimelineEvents.length - 1 && (
            <div className={['grayLineStyling', cancelGrayTimeLineStyle(timeline)].join(' ')} />
          )}
        </td>
        <td
          className={timeline ? 'taskInformationTimelineContainerStyling' : 'taskInformationContainerStyling'}
        >
          <CaseDetailsDescriptionList>
            {timeline && timelineTitle}
            {this.showTimelineDescriptionItems(task)}
          </CaseDetailsDescriptionList>
        </td>
        {!timeline && (
          <td className="taskContainerStyling taskActionsContainerStyling">
            {this.showActionsListItem(task, correspondence)}
          </td>
        )}
      </tr>
    );
  };

  render = () => {
    const { correspondence, taskList } = this.props;

    const sortedTimelineEvents = sortCaseTimelineEvents(taskList);

    return (
      <React.Fragment key={correspondence.uuid}>
        {sortedTimelineEvents.map((timelineEvent, index) => {
          const templateConfig = {
            task: timelineEvent,
            index,
            sortedTimelineEvents,
            correspondence,
          };

          return this.taskTemplate(templateConfig);
        })}
      </React.Fragment>
    );
  };
}

CorrespondenceTaskRows.propTypes = {
  correspondence: PropTypes.object,
  hideDropdown: PropTypes.bool,
  taskList: PropTypes.array,
  timeline: PropTypes.bool,
  showActionsDropdown: PropTypes.bool,
};

const mapStateToProps = (state) => ({
  showActionsDropdown: state.correspondenceDetails.showActionsDropdown,
});

export default connect(
  mapStateToProps
)(CorrespondenceTaskRows);
