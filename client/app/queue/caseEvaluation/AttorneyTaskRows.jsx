/* eslint-disable max-lines */
import { css } from 'glamor';
import React from 'react';
import moment from 'moment';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import COPY from '../../../COPY';
import { sortCaseTimelineEvents } from '../utils';

class AttorneyTaskRows extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      timelineIsVisible: {},
      activeTasks: [...props.taskList],
    };
  }

  toggleTimelineVisibility = (appeal) => {
    const previousState = Object.assign(
      {},
      this.state.timelineIsVisible
    );

    previousState[appeal.uniqueId] = previousState[appeal.uniqueId] ?
      !previousState[appeal.uniqueId] :
      true;
    this.setState({ timelineIsVisible: previousState });
  };

  datesTaskWorked = (task) => {
    if (task) {
      const dateCreated = moment(task.createdAt).format('MM/DD/YYYY');
      const dateClosed = task.closedAt ? moment(task.closedAt).format('MM/DD/YYYY') : '';
      const taskDateFormat = ` (${dateCreated} - ${dateClosed})`;

      return (
        <React.Fragment>
          {taskDateFormat}
        </React.Fragment>
      );
    }
  }

  showTimelineDescriptionSplitItems = (task) => {
    return (
      <React.Fragment>
        {this.splitByListItem(task)}
      </React.Fragment>
    );
  };

  taskTemplate = (templateConfig) => {
    const {
      task,
      timeline,
    } = templateConfig;

    return (
      <tr key={task.uniqueId}>
        <td className="attorneyTaskTimelineContainer">
          <div></div>
        </td>
        <td className="grayLineContainer" >
          <div className="grayLineStyling" />
        </td>
        <td className={timeline ? 'attorneyTaskContainer' : ''} >
          {task.label}{this.datesTaskWorked(task)}
        </td>
      </tr>
    );
  };

  hideShowTimelineButton = (appeal, taskList) => {
    let button = (<span>{COPY.TASK_SNAPSHOT_NO_TASKS_TO_SHOW}</span>);

    if (taskList.length > 0) {
      button = (<Button
        linkStyling
        styling={css({ padding: '0' })}
        id={appeal.uniqueId}
        name={
          this.state.timelineIsVisible[appeal.uniqueId] ?
            COPY.TASK_SNAPSHOT_HIDE_TIMELINE_LABEL :
            COPY.TASK_SNAPSHOT_VIEW_TIMELINE_LABEL
        }
        onClick={() => this.toggleTimelineVisibility(appeal)}
      />);
    }

    return (<tr className="attorneyTaskTimelineContainer" >
      <td className="attorneyTaskTimelineContainer"></td>
      <td className="grayLineContainer" >
        <div className="grayLineStyling" />
      </td>
      <td className="attorneyTaskContainer" >
        {button}
      </td>
    </tr>);
  }

  // Certain events are only relevant to full timeline view
  render = () => {
    const { appeal, taskList, timeline } = this.props;

    // Reverse the result so oldest tasks show at top of timeline
    const sortedTimelineEvents = sortCaseTimelineEvents(
      taskList,
    ).reverse();

    return (
      <React.Fragment key={appeal.externalId}>
        {this.state.timelineIsVisible[appeal.uniqueId] && sortedTimelineEvents.map((timelineEvent, index) => {

          const templateConfig = {
            task: timelineEvent,
            index,
            timeline,
            sortedTimelineEvents,
            appeal,
          };

          return this.taskTemplate(templateConfig);
        })}
        {this.hideShowTimelineButton(appeal, taskList)}
      </React.Fragment>
    );
  };
}

AttorneyTaskRows.propTypes = {
  appeal: PropTypes.object,
  taskList: PropTypes.array,
  timeline: PropTypes.bool,
};

export default AttorneyTaskRows;
