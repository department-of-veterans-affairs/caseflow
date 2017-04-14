import React, { PropTypes } from 'react';
import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';


export default class UnpreparedTasksIndex extends React.Component {
  render() {
    let {
      unpreparedTasks
    } = this.props;

    let tableColumns = [
      {
        header: 'Veteran',
        valueFunction: (task) =>
          `${task.cached_veteran_name} (${task.vbms_id})`
      },
      {
        header: 'Decision Type',
        valueFunction: (task) => task.cached_decision_type
      },
      {
        header: 'Decision Date',
        valueFunction: (task) => formatDate(task.cached_serialized_decision_date)
      },
      {
        header: 'Days in Queue',
        valueFunction: (task) => `${task.days_since_creation} days`
      }
    ];

    return <div className="cf-app-segment cf-app-segment--alt">
      <h1>Claims Missing Decisions - {formatDate(new Date().toDateString())}</h1>

      <div className="usa-grid-full">
        <Table
          columns={tableColumns}
          rowObjects={unpreparedTasks}
          summary="Appeals missing decisions" />
      </div>
    </div>;
  }
}

UnpreparedTasksIndex.propTypes = {
  unpreparedTasks: PropTypes.arrayOf(PropTypes.object)
};
