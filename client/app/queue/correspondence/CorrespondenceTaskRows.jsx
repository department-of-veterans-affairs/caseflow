import { css } from 'glamor';
import React from 'react';
import moment from 'moment';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import COPY from '../../../COPY';
import { CancelIcon } from '../../components/icons/CancelIcon';
import { GrayDotIcon } from '../../components/icons/GrayDotIcon';
import { GreenCheckmarkIcon } from '../../components/icons/GreenCheckmarkIcon';
import { COLORS } from '../../constants/AppConstants';
import { sortCaseTimelineEvents } from '../utils';
import CaseDetailsDescriptionList from '../components/CaseDetailsDescriptionList';
import ActionsDropdown from '../components/ActionsDropdown';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';

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
  return (task.closedAt && timeline ? <GreenCheckmarkIcon /> : <GrayDotIcon size={25} />);
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

const establishmentTask = (task) => {
  return task.type === 'EstablishmentTask';
};

const tdClassNames = (timeline, task) => {
  const containerClass = timeline ? taskInfoWithIconTimelineContainer : '';
  const closedAtClass = task.closedAt ? null : <span className="greyDotTimelineStyling"></span>;

  return [containerClass, closedAtClass].filter((val) => val).join(' ');
};

const cancelGrayTimeLineStyle = (timeline) => {
  return timeline ? grayLineTimelineStyling : '';
};

class CorrespondenceTaskRows extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      taskInstructionsIsVisible: [],
      showEditNodDateModal: false,
      activeTasks: [...props.taskList],
    };
  }

  toggleTaskInstructionsVisibility = (taskKey) => {
    if (this.state.taskInstructionsIsVisible.includes(taskKey)) {
      const state = this.state.taskInstructionsIsVisible;

      const index = this.state.taskInstructionsIsVisible.indexOf(taskKey);

      state.splice(index, 1);
      this.setState({ taskInstructionsIsVisible: [...state] });
    } else {
      const state = this.state.taskInstructionsIsVisible;

      state.push(taskKey);
      this.setState({ taskInstructionsIsVisible: [...state] });
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
    if (!task.instructions || !task.instructions.length) {
      return <br />;
    }

    // We specify the same 2.4rem margin-bottom as paragraphs to each set of instructions
    // to ensure a consistent margin between instruction content and the "Hide" button
    const divStyles = { marginBottom: '2.4rem', marginTop: '1em' };

    return (
      <React.Fragment key={`${task.uniqueId} fragment`}>
        {task.instructions.map((text) => (
          <React.Fragment key={`${task.uniqueId} div`}>
            <div
              key={`${task.uniqueId} instructions`}
              style={divStyles}
              className="task-instructions"
            >
              <p>{text}</p>
            </div>
          </React.Fragment>
        ))}
      </React.Fragment>
    );
  };

  taskInstructionsListItem = (task) => {
    if (!task.instructions || !task.instructions.length > 0) {
      return null;
    }

    const taskInstructionsVisible = this.state.taskInstructionsIsVisible.includes(task.label);

    return (
      <div className="cf-row-wrapper">
        {taskInstructionsVisible && (
          <React.Fragment key={`${task.assignedOn}${task.label}`}>
            {!establishmentTask(task) &&
            <dt style={{ width: '100%' }}>
              {COPY.TASK_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}
            </dt>
            }
            <dd style={{ width: '100%' }}>
              {this.taskInstructionsWithLineBreaks(task)}
            </dd>
          </React.Fragment>
        )}
        <Button
          linkStyling
          styling={css({ padding: '0' })}
          id={task.uniqueId}
          name={
            taskInstructionsVisible ?
              COPY.TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL :
              COPY.TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
          }
          onClick={() => this.toggleTaskInstructionsVisibility(task.label)}
        />
      </div>
    );
  };

  showActionsListItem = (task, correspondence) => {
    if (task.availableActions.length <= 0) {
      return null;
    }

    return this.showActionsSection(task) ? (
      <div>
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
      correspondence,
    } = templateConfig;

    const timelineTitle = isCancelled(task) ?
      `${task.type} cancelled` :
      task.timelineTitle;

    return (
      <tr key={task.uniqueId}>
        <td
          {...taskTimeContainerStyling}
          className={timeline ? taskTimeTimelineContainerStyling : ''}
        >
          <CaseDetailsDescriptionList>
            {this.assignedOnListItem(task)}
          </CaseDetailsDescriptionList>

        </td>
        <td
          {...taskInfoWithIconContainer}
          className={tdClassNames(timeline, task)}
        >
          {isCancelled(task) ? <CancelIcon /> : closedAtIcon(task, timeline)}

          {((index < sortedTimelineEvents.length && timeline) ||
            (index < this.state.activeTasks.length - 1 && !timeline)) && (
            <div
              {...grayLineStyling}
              className={[
                cancelGrayTimeLineStyle(timeline),
                task.closedAt ? '' : greyDotAndlineStyling,
              ].join(' ')}
            />
          )}
        </td>
        <td
          {...taskInformationContainerStyling}
          className={timeline ? 'taskInformationTimelineContainerStyling' : ''}
        >
          <CaseDetailsDescriptionList>
            {timeline && timelineTitle}
            {this.showTimelineDescriptionItems(task)}
          </CaseDetailsDescriptionList>

        </td>
        {!timeline && (
          <td className="taskContainerStyling taskActionsContainerStyling">
            {this.showActionsListItem(task, correspondence)}{' '}
          </td>
        )}
      </tr>
    );
  };

  render = () => {
    const { correspondence, taskList } = this.props;
    // Non-tasks are only relevant for the main Case Timeline
    const sortedTimelineEvents = sortCaseTimelineEvents(
      taskList,
    );

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
};

export default CorrespondenceTaskRows;
