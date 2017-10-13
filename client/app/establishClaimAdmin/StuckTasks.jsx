import React, { Component } from 'react';
import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';
import moment from 'moment';

const UNASSIGNED_TASKS_COLUMNS = [
  {
    header: 'Veteran',
    valueFunction: (task) =>
      <span>{task.cached_veteran_name}
        <span className="vbms-id"> ({task.vbms_id})</span>
      </span>
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
    header: 'Days Since Decision Upload',
    valueFunction: (task) => moment(task.prepared_at).fromNow(true)
  }
];

export default class StuckTasks extends Component {

  getKeyForRow = (index, task) => task.id

  render() {
    return <div className="cf-app-segment--alt">
      <h1 className="title">Oldest Unassigned Tasks with Uploaded Decisions</h1>

      <Table
        className="cf-work-assignments"
        columns={UNASSIGNED_TASKS_COLUMNS}
        rowObjects={this.props.tasks}
        summary="Appeals stuck in ARC Dispatch"
        getKeyForRow={this.getKeyForRow}
      />
    </div>;
  }
}
