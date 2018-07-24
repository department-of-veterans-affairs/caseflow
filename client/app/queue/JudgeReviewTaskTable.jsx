import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import Table from '../components/Table';
import CaseDetailsLink from './CaseDetailsLink';

import { judgeReviewTasksSelector } from './selectors';
import { sortTasks, renderAppealType, getTaskDaysWaiting } from './utils';
import COPY from '../../COPY.json';

class JudgeReviewTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.appealId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  getQueueColumns = () => [{
    header: COPY.JUDGE_QUEUE_TABLE_VETERAN_NAME_COLUMN_TITLE,
    valueFunction: (task) => <CaseDetailsLink task={task} appeal={this.getAppealForTask(task)} />
  }, {
    header: COPY.JUDGE_QUEUE_TABLE_DOCUMENT_ID_COLUMN_TITLE,
    valueFunction: (task) => {
      if (!task.attributes.assigned_by_first_name) {
        return task.attributes.document_id;
      }
      const firstInitial = String.fromCodePoint(task.attributes.assigned_by_first_name.codePointAt(0));
      const nameAbbrev = `${firstInitial}. ${task.attributes.assigned_by_last_name}`;

      return <React.Fragment>
        {task.attributes.document_id}<br />from {nameAbbrev}
      </React.Fragment>;
    }
  }, {
    header: COPY.JUDGE_QUEUE_TABLE_APPEAL_TYPE_COLUMN_TITLE,
    valueFunction: (task) => renderAppealType(this.getAppealForTask(task))
  }, {
    header: COPY.JUDGE_QUEUE_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
    valueFunction: (task) => this.getAppealForTask(task, 'docket_number')
  }, {
    header: COPY.JUDGE_QUEUE_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
    valueFunction: (task) => this.getAppealForTask(task, 'issues.length')
  }, {
    header: COPY.JUDGE_QUEUE_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
    valueFunction: getTaskDaysWaiting,
    getSortValue: getTaskDaysWaiting
  }];

  render = () => <Table
    columns={this.getQueueColumns}
    rowObjects={sortTasks(_.pick(this.props, 'tasks', 'appeals'))}
    getKeyForRow={this.getKeyForRow} />;
}

JudgeReviewTaskTable.propTypes = {
  appeals: PropTypes.object.isRequired,
  tasks: PropTypes.object.isRequired
};

const mapStateToProps = (state) => {
  const {
    queue: {
      appeals
    }
  } = state;

  return {
    appeals,
    tasks: judgeReviewTasksSelector(state)
  };
};

export default connect(mapStateToProps)(JudgeReviewTaskTable);
