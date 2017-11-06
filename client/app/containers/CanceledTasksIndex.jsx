import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';

import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';

export default class CanceledTasksIndex extends React.Component {
  render() {

    let {
      canceledTasks
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
        header: 'Cancel Date',
        valueFunction: (task) => formatDate(new Date(`${task.completed_at}`))
      },
      {
        header: 'Reason',
        valueFunction: (task) => task.comment
      }
    ];

    let dateRange = () => {
      let today = new Date();
      let todaysDate = moment(today.toISOString());
      let fiveWeeksAgo = moment(today.toISOString()).subtract(5, 'weeks');

      return `${fiveWeeksAgo.format('L')} - ${todaysDate.format('L')}`;
    };

    return <div className="cf-app-segment cf-app-segment--alt">
      <div className="cf-title-meta-right">
        <h1 className="title">Canceled EPs</h1>
        <div className="meta">{ dateRange() }</div>
      </div>

      <div className="usa-grid-full">
        <Table
          columns={tableColumns}
          rowObjects={canceledTasks}
          summary={`Canceled EPs: ${dateRange()}`} />
      </div>
    </div>;
  }
}

CanceledTasksIndex.propTypes = {
  canceledTasks: PropTypes.arrayOf(PropTypes.object)
};
