import React, { PropTypes } from 'react';
import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';

const TABLE_HEADERS = ['Veteran', 'Decision Type', 'Decision Date', 'Days in Queue'];

export default class UnpreparedTasksIndex extends React.Component {

  buildUnpreparedTaskRow = (task) => [
    `${task.appeal.veteran_name} (${task.appeal.vbms_id})`,
    task.appeal.decision_type,
    formatDate(task.appeal.decision_date),
    `${task.appeal.days_since_decision} days`
  ];

  render() {
    let {
      unpreparedTasks
    } = this.props;

    return <div className="cf-app-segment cf-app-segment--alt">
      <h1>Claims Missing Decisions - {formatDate(new Date().toDateString())}</h1>

      <div className="usa-grid-full">
        <Table
          headers={TABLE_HEADERS}
          buildRowValues={this.buildUnpreparedTaskRow}
          values={unpreparedTasks}
        />
      </div>
    </div>;
  }
}

UnpreparedTasksIndex.propTypes = {
  unpreparedTasks: PropTypes.arrayOf(PropTypes.object)
};
