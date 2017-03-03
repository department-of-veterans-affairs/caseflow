import React, { PropTypes } from 'react';

import ApiUtil from '../../util/ApiUtil';
import BaseForm from '../BaseForm';
import Table from '../../components/Table';
import Button from '../../components/Button';
import { formatDate } from '../../util/DateUtil';

const TABLE_HEADERS = [
  'Veteran',
  'Decision Date',
  'Decision Type',
  'Action'
];
const COLUMN_CLASSES = ['cf-txt-l ', 'cf-txt-c', 'cf-txt-c', 'cf-txt-c'];

export default class CaseWorkerIndex extends BaseForm {

  buildUserRow = (caseInformation) =>
    [
      `${caseInformation.appeal.veteran_name} (${caseInformation.appeal.vbms_id})`,
      formatDate(caseInformation.completed_at),
      caseInformation.appeal.decision_type,
      caseInformation.completion_status_text
    ]

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
            headers={TABLE_HEADERS}
            buildRowValues={this.buildUserRow}
            values={this.props.currentUserHistoricalTasks}
            columnClasses={COLUMN_CLASSES}
          />
        </div>;
  }
}

CaseWorkerIndex.propTypes = {
  currentUserHistoricalTasks: PropTypes.array
};
