import React, { PropTypes } from 'react';

import ApiUtil from '../../util/ApiUtil';
import BaseForm from '../BaseForm';
import Table from '../../components/Table';
import Button from '../../components/Button';
import { formatDate } from '../../util/DateUtil';

export default class CaseWorkerIndex extends BaseForm {
  onClick = () => {
    ApiUtil.patch(`/dispatch/establish-claim/assign`).then((response) => {
      window.location = `/dispatch/establish-claim/${response.body.next_task_id}`;
    }, () => {
      this.props.handleAlert(
        'error',
        'Error',
        'There was an error assigning a task. Please try again later'
      );
    });
  };

  render() {
    let {
      availableTasks,
      buttonText
    } = this.props;

    let workHistoryColumns = [
      {
        header: 'Veteran',
        valueFunction: (task) =>
          `${task.appeal.veteran_name} (${task.appeal.vbms_id})`
      },
      {
        header: 'Decision Date',
        valueFunction: (task) => formatDate(task.completed_at)
      },
      {
        header: 'Decision Type',
        valueFunction: (task) => task.appeal.decision_type
      },
      {
        header: 'Action',
        valueName: 'completion_status_text'
      }
    ];

    return <div className="cf-app-segment cf-app-segment--alt">
          <div className="usa-width-one-whole task-start-wrapper">
            <div className="cf-right-side">
              <span className="cf-button-associated-text-right">
                { availableTasks &&
                  `${this.props.totalAssignedIssues} cases assigned, ${
                this.props.completedCountToday} completed`
                }
                { !availableTasks &&
                  "There are no more claims in your queue."
                }
              </span>
              { availableTasks &&
              <Button
                name={buttonText}
                onClick={this.onClick}
                classNames={["usa-button-primary", "cf-push-right",
                  "cf-button-aligned-with-textfield-right"]}
                disabled={!availableTasks}
              />
              }
              { !availableTasks &&
              <Button
                  name={buttonText}
                  classNames={["usa-button-disabled", "cf-push-right",
                    "cf-button-aligned-with-textfield-right"]}
                  disabled={true}
              />
              }
            </div>
          </div>
          <h1>Work History</h1>
          <Table
            columns={workHistoryColumns}
            rowObjects={this.props.currentUserHistoricalTasks}
          />
        </div>;
  }
}

CaseWorkerIndex.propTypes = {
  currentUserHistoricalTasks: PropTypes.array
};
