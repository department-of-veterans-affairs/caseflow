import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';
import moment from 'moment';

import Table from '../components/Table';
import CaseDetailsLink from './CaseDetailsLink';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { sortTasks, renderAppealType } from './utils';
import COPY from '../../../COPY.json';

class JudgeReviewTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  getCaseDetailsLink = (task) => <CaseDetailsLink task={task} appeal={this.getAppealForTask(task)} />;

  getQueueColumns = () => [
    {
      header: COPY.JUDGE_QUEUE_TABLE_VETERAN_NAME_COLUMN_TITLE,
      valueFunction: this.getCaseDetailsLink
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_DOCUMENT_ID_COLUMN_TITLE,
      valueFunction: (task) => {
        const firstInitial = String.fromCodePoint(task.attributes.assigned_by_first_name.codePointAt(0));
        const nameAbbrev = `${firstInitial}. ${task.attributes.assigned_by_last_name}`;

        return <React.Fragment>
          {task.attributes.document_id}<br />from {nameAbbrev}
        </React.Fragment>;
      }
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_APPEAL_TYPE_COLUMN_TITLE,
      valueFunction: (task) => renderAppealType(this.getAppealForTask(task))
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (task) => this.getAppealForTask(task, 'docket_number')
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
      valueFunction: (task) => this.getAppealForTask(task, 'issues.length')
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
      valueFunction: (task) => (
        moment().
          startOf('day').
          diff(moment(task.attributes.assigned_on), 'days'))
    },
    {
      // todo: replace
      header: 'asdf',
      valueFunction: (task) => <Link to={`/queue/appeals/${task.vacolsId}/evaluate`}>
        Evaluate Decision
      </Link>
    }
  ];

  render = () => {
    return <Table
      columns={this.getQueueColumns}
      rowObjects={
        sortTasks(
          _.pick(this.props, 'tasks', 'appeals')
        ).filter((task) => task.attributes.task_type === 'Review')
      }
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

JudgeReviewTaskTable.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

export default connect(mapStateToProps)(JudgeReviewTaskTable);
