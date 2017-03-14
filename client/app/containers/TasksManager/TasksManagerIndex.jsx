import React, { PropTypes } from 'react';

import ApiUtil from '../../util/ApiUtil';
import TasksManagerEmployeeCount from './TasksManagerEmployeeCount';
import BaseForm from '../BaseForm';
import Table from '../../components/Table';
import FormField from '../../util/FormField';

export default class TasksManagerIndex extends BaseForm {
  constructor(props) {
    super(props);

    let totalCases = this.props.toCompleteCount + this.props.completedCountToday;
    let assignedCases = this.props.employeeCount > 0 ?
      Math.ceil(totalCases / this.props.employeeCount) : 0;

    this.state = {
      assignedCases,
      employeeCountForm: {
        employeeCount: new FormField(this.props.employeeCount)
      }
    };
  }

  getUserColumns = () => {
    // We return an empty row if there are no users in the table. Otherwise
    // we use the footer to display the totals.
    let noUsers = Object.keys(this.props.tasksCompletedByUsers).length === 0;

    return [
      {
        header: 'Employee Name',
        valueName: 'name',
        footer: noUsers ? "" : <b>Employee Total</b>
      },
      {
        header: 'Cases Assigned',
        valueFunction: () => this.state.assignedCases,
        footer: noUsers ?
          "0" :
          <b>{this.props.toCompleteCount + this.props.completedCountToday}</b>
      },
      {
        header: 'Cases Completed',
        valueName: 'numberOfTasks',
        footer: noUsers ? "0" : <b>{this.props.completedCountToday}</b>
      },
      {
        header: 'Cases Remaining',
        valueFunction: (user) =>
          Math.max(this.state.assignedCases - user.numberOfTasks, 0),
        footer: this.props.toCompleteCount
      }
    ];
  }

  handleEmployeeCountUpdate = () => {
    let count = this.state.employeeCountForm.employeeCount.value;

    return ApiUtil.patch(`/dispatch/employee-count/${count}`).then(() => {
      window.location.reload();
    }, () => {
      this.props.handleAlert(
        'error',
        'Error',
        'There was an error while updating the employee count. Please try again later'
      );
    });
  };

  render() {
    let {
      completedCountToday,
      toCompleteCount
    } = this.props;

    let tasksCompletedByUsers = Object.keys(this.props.tasksCompletedByUsers).
      map((name) => ({ name,
        numberOfTasks: this.props.tasksCompletedByUsers[name] }));

    return <div className="cf-app-segment cf-app-segment--alt">
      <h1>ARC Work Assignments
        <span className="cf-associated-header">
          {completedCountToday} out
          of {(toCompleteCount + completedCountToday)} cases completed today
        </span>
      </h1>
      <TasksManagerEmployeeCount
        employeeCountForm={this.state.employeeCountForm}
        handleEmployeeCountUpdate={this.handleEmployeeCountUpdate}
        handleFieldChange={this.handleFieldChange}
      />
      <div className="cf-right-side">
        <a>
          <i className="fa fa-line-chart" aria-hidden="true"></i> View Dashboard
        </a>
      </div>
      <Table
        columns={this.getUserColumns()}
        rowObjects={tasksCompletedByUsers}
        summary="Appeals worked by user"
      />
    </div>;
  }
}

TasksManagerIndex.propTypes = {
  completedCountToday: PropTypes.number.isRequired,
  employeeCount: PropTypes.string.isRequired,
  tasksCompletedByUsers: PropTypes.object.isRequired,
  toCompleteCount: PropTypes.number.isRequired
};
