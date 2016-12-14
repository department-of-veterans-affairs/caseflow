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
      <h1>Work Flow
        <span className="cf-associated-header">
          {completedCountToday} cases processed today, {toCompleteCount} in queue
        </span>
      </h1>

      <div className="usa-grid-full">
        <div className="usa-width-one-half">
          <h2>Current</h2>
        </div>
      </div>

      <div className="usa-grid-full">
        <Table
          headers={TABLE_HEADERS}
          buildRowValues={this.buildTaskRow}
          values={currentTasks}
        />
      </div>
      <hr className="cf-section-break" />

      <div className="usa-grid-full">
        <div className="usa-width-one-half">
          <h2>Work History</h2>
        </div>
      </div>

      <div className="usa-grid-full">
        <Table
          headers={TABLE_HEADERS}
          buildRowValues={this.buildTaskRow}
          values={completedTasks}
        />
      </div>
      <div className="usa-grid-full">
        {this.isRemainingTasksToDownload() && <span className="cf-right-side">
          {isLoadingTasks ?
            <span>Loading More...</span> :
            <a
              href="#"
              id="fetchCompletedTasks"
              className="cf-right-side"
              onClick={this.fetchCompletedTasks}
            >
              Show More
            </a>
          }
        </span>}
      </div>

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
