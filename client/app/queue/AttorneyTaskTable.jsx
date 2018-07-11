// @flow
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import { css } from 'glamor';
import moment from 'moment';
import pluralize from 'pluralize';

import Table from '../components/Table';
import ReaderLink from './ReaderLink';
import CaseDetailsLink from './CaseDetailsLink';

import { sortTasks, renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';
import { CATEGORIES, redText } from './constants';
import COPY from '../../COPY.json';

import type {
  Tasks,
  LegacyAppeals
} from './types/models';

type Props = {|
  loadedQueueTasks: Tasks,
  appeals: LegacyAppeals,
  tasks: Tasks,
  featureToggles: Object
|};

class AttorneyTaskTable extends React.PureComponent<Props> {
  getKeyForRow = (rowNumber, object) => object.id;
  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.appealId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  tableStyle = css({
    '& > tr > td': {
      '&:last-of-type': {
        width: this.props.featureToggles.phase_two ? '25%' : ''
      }
    }
  });
  collapseColumnIfNoDASRecord = (task) => task.attributes.task_id ? 1 : 0;

  getQueueColumns = () => [{
    header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
    valueFunction: (task) => <CaseDetailsLink
      task={task}
      appeal={this.getAppealForTask(task)}
      disabled={!task.attributes.task_id} />,
    getSortValue: (task) => this.getAppealForTask(task, 'veteran_full_name')
  }, {
    header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
    valueFunction: (task) => task.attributes.task_id ?
      renderAppealType(this.getAppealForTask(task)) :
      <span {...redText}>{COPY.ATTORNEY_QUEUE_TABLE_TASK_NEEDS_ASSIGNMENT_ERROR_MESSAGE}</span>,
    span: (task) => task.attributes.task_id ? 1 : 5
  }, {
    header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
    valueFunction: (task) => task.attributes.task_id ? this.getAppealForTask(task, 'docket_number') : null,
    span: this.collapseColumnIfNoDASRecord,
    getSortValue: (task) => task.attributes.task_id ? this.getAppealForTask(task, 'docket_number') : null
  }, {
    header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
    valueFunction: (task) => task.attributes.task_id ? this.getAppealForTask(task, 'issues.length') : null,
    span: this.collapseColumnIfNoDASRecord,
    getSortValue: (task) => task.attributes.task_id ? this.getAppealForTask(task, 'issues.length') : null
  }, {
    header: COPY.CASE_LIST_TABLE_DAYS_WAITING_COLUMN_TITLE,
    tooltip: <React.Fragment>Calendar days this case <br /> has been assigned to you</React.Fragment>,
    valueFunction: (task) => {
      if (!task.attributes.task_id) {
        return null;
      }

      const daysWaiting = moment().
        diff(moment(task.attributes.assigned_on), 'days');

      return <React.Fragment>
        {daysWaiting} {pluralize('day', daysWaiting)} - <DateString date={task.attributes.due_on} />
      </React.Fragment>;
    },
    span: this.collapseColumnIfNoDASRecord,
    getSortValue: (task) => moment().diff(moment(task.attributes.assigned_on), 'days')
  }, {
    header: COPY.CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
    span: this.collapseColumnIfNoDASRecord,
    valueFunction: (task) => {
      if (!task.attributes.task_id) {
        return null;
      }

      return <ReaderLink appealId={task.appealId}
        analyticsSource={CATEGORIES.QUEUE_TABLE}
        redirectUrl={window.location.pathname}
        appeal={this.props.appeals[task.appealId]} />;
    }
  }];

  render = () => {
    const { appeals, loadedQueueTasks, tasks } = this.props;
    const taskWithId = {};

    for (const id of Object.keys(loadedQueueTasks)) {
      taskWithId[id] = tasks[id];
    }

    return <Table
      columns={this.getQueueColumns}
      rowObjects={sortTasks({
        appeals,
        tasks: taskWithId
      })}
      getKeyForRow={this.getKeyForRow}
      rowClassNames={(task) => task.attributes.task_id ? null : 'usa-input-error'}
      bodyStyling={this.tableStyle} />;
  }
}

const mapStateToProps = (state) => {
  const {
    queue: {
      loadedQueue: {
        tasks: loadedQueueTasks,
        appeals
      },
      tasks
    },
    ui: {
      featureToggles
    }
  } = state;

  return {
    loadedQueueTasks,
    appeals,
    tasks,
    featureToggles
  };
};

export default connect(mapStateToProps)(AttorneyTaskTable);
