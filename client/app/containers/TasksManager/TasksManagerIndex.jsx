import React, { PropTypes } from 'react';
import _uniqBy from 'lodash/uniqBy';

import ApiUtil from '../../util/ApiUtil';
import TasksManagerEmployeeCount from './TasksManagerEmployeeCount';
import BaseForm from '../BaseForm';
import Table from '../../components/Table';
import FormField from '../../util/FormField';

const TABLE_HEADERS = ['Employee Name', 'Cases Assigned', 'Cases Completed', 'Cases Remaining'];

export default class TasksManagerIndex extends BaseForm {
  constructor(props) {
    super(props);

    let totalCases = this.props.toCompleteCount + this.props.completedCountToday;
    let assignedCases = this.props.employeeCount > 0 ? Math.ceil( totalCases / this.props.employeeCount) : 0
    
    this.state = {
      assignedCases: assignedCases,
      employeeCountForm: {
        employeeCount: new FormField(this.props.employeeCount)
      }
    };
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

  buildUserRow = (user) => {
    let {
      completedCountToday,
      tasksCompletedByUsers,
      toCompleteCount
    } = this.props;


    return [
      user,
      this.state.assignedCases,
      tasksCompletedByUsers[user],
      this.state.assignedCases - tasksCompletedByUsers[user]
    ];
  }

  render() {
    let {
      completedCountToday,
      toCompleteCount
    } = this.props;

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
      <h2>
        Work Assignments
      </h2>
      <Table
        headers={TABLE_HEADERS}
        buildRowValues={this.buildUserRow}
        values={Object.keys(this.props.tasksCompletedByUsers)}
      />
    </div>;
  }
}

TasksManagerIndex.propTypes = {
  completedCountToday: PropTypes.number.isRequired,
  employeeCount: PropTypes.string.isRequired,
  toCompleteCount: PropTypes.number.isRequired
};
