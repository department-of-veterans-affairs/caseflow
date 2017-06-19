import React from 'react';
import PropTypes from 'prop-types';

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
        header: 'Days Since Outcoding',
        valueFunction: (task) => `${task.days_since_creation} days`
      }
    ];

    return <div className="cf-app-segment cf-app-segment--alt">
      <div className="cf-title-meta-right">
        <h1 className="cf-push-left">Claims Missing Decisions in VBMS</h1>
        <div className="cf-push-right">
          <span className="meta">Total missing:
            <span className="value"> {unpreparedTasks.length}</span>
          </span>
        </div>
      </div>

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
