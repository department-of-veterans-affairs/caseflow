import React, { PropTypes } from 'react';

import ApiUtil from '../util/ApiUtil';

import Table from '../components/Table';

const TABLE_HEADERS = ['Name', 'Veteran ID', 'Status', 'Worked By'];

export default class TasksManagerIndex extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
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
    task.user && task.user.css_id
  ]

  isRemainingTasksToDownload = () => {
    let { completedTasks } = this.state;
    let { completedCountTotal } = this.props;

    return completedTasks.length < completedCountTotal;
  }


  fetchCompletedTasks = (event) => {
    let {
      completedTasks,
      completedTasksPage
    } = this.state;

    event.preventDefault();
    this.setState({ isLoadingTasks: true });
    let incrementedTaskPage = completedTasksPage + 1;

    ApiUtil.get(`/dispatch/establish-claim`, {
      query: { page: incrementedTaskPage }
    }).then((response) => {
      this.setState({
        completedTasks: completedTasks.concat(response.body.completedTasks),
        completedTasksPage: incrementedTaskPage,
        isLoadingTasks: false
      });
    }, () => {
      this.setState({ isLoadingTasks: false });
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
