import React, { PropTypes } from 'react';
import _uniqBy from 'lodash/uniqBy';

import ApiUtil from '../util/ApiUtil';

import Table from '../components/Table';

const TABLE_HEADERS = ['Name', 'Veteran ID', 'Status', 'Worked By'];

export default class TasksManagerIndex extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      completedCountTotal: props.completedCountTotal,
      completedTasks: props.completedTasks,
      // zero-based indexing for pages
      completedTasksPage: 0,
      isLoadingTasks: false
    };
  }

  buildTaskRow = (task) => [
    task.appeal.veteran_name,
    task.appeal.vbms_id,
    task.progress_status,
    task.user && task.user.full_name
  ]

  isRemainingTasksToDownload = () => {
    let { completedTasks, completedCountTotal } = this.state;

    return completedTasks.length < completedCountTotal;
  }

  // This method takes the existing completed tasks and appends the new
  // ones, checking for duplicates and removing them
  mergeCompletedTasks = (newCompletedTasks) => {
    let tasks = this.state.completedTasks.concat(newCompletedTasks);


    return _uniqBy(tasks, (task) => task.id);
  }


  fetchCompletedTasks = (event) => {
    let { handleAlert, handleAlertClear } = this.props;
    let { completedCountTotal, completedTasksPage } = this.state;

    event.preventDefault();
    handleAlertClear();
    this.setState({ isLoadingTasks: true });

    let incrementedTaskPage = completedTasksPage + 1;

    ApiUtil.get(`/dispatch/establish-claim`, {
      query: {
        expectedCompletedTotal: completedCountTotal,
        page: incrementedTaskPage
      }
    }).then((response) => {
      this.setState({
        completedTasks: this.mergeCompletedTasks(response.body.completedTasks),
        completedTasksPage: incrementedTaskPage,
        completedTasksTotal: response.body.completedCountTotal,
        isLoadingTasks: false
      });
    }, () => {
      this.setState({ isLoadingTasks: false });
      handleAlert(
        'error',
        'Error',
        'There was an error while loading work history. Please try again later'
      );
    });
  }

  render() {
    let {
      completedCountToday,
      toCompleteCount,
      currentTasks
    } = this.props;

    let {
      completedTasks,
      isLoadingTasks
    } = this.state;

    return <div className="cf-app-segment cf-app-segment--alt">
      <h1>ARC Workflow
        <span className="cf-associated-header">
          {completedCountToday} out of {(toCompleteCount + completedCountToday)} cases completed today
        </span>
      </h1>
    </div>;
  }
}

TasksManagerIndex.propTypes = {
  completedCountToday: PropTypes.number.isRequired,
  completedCountTotal: PropTypes.number.isRequired,
  completedTasks: PropTypes.arrayOf(PropTypes.object).isRequired,
  currentTasks: PropTypes.arrayOf(PropTypes.object).isRequired,
  toCompleteCount: PropTypes.number.isRequired
};
