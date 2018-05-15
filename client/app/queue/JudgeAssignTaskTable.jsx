import CaseDetailsLink from './CaseDetailsLink';
import PropTypes from 'prop-types';
import React from 'react';
import Table from '../components/Table';
import _ from 'lodash';
import moment from 'moment';
import { renderAppealType } from './utils';
import AppealDocumentCount from './AppealDocumentCount';
import COPY from '../../../COPY.json';

export default class JudgeAssignTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, { task }) => task.id;

  getCaseDetailsLink = ({ task, appeal }) => <CaseDetailsLink task={task} appeal={appeal} />;

  getQueueColumns = () => [
    {
      header: COPY.JUDGE_QUEUE_TABLE_SELECT_COLUMN_TITLE,
      valueFunction: () => 'Box'
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_VETERAN_NAME_COLUMN_TITLE,
      valueFunction: this.getCaseDetailsLink
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_APPEAL_TYPE_COLUMN_TITLE,
      valueFunction: ({ appeal }) => renderAppealType(appeal)
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: ({ appeal }) => _.get(appeal.attributes, 'docket_number')
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
      valueFunction: ({ appeal }) => _.get(appeal.attributes, 'issues.length')
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
      valueFunction: ({ appeal }) => <AppealDocumentCount appeal={appeal} />
    },
    {
      header: COPY.JUDGE_QUEUE_TABLE_TASK_DAYS_WAITING_COLUMN_TITLE,
      valueFunction: ({ task }) => (
        moment().
          startOf('day').
          diff(moment(task.attributes.assigned_on), 'days'))
    }
  ];

  render = () => {
    return <Table
      columns={this.getQueueColumns}
      rowObjects={this.props.tasksAndAppeals}
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

JudgeAssignTaskTable.propTypes = {
  tasksAndAppeals: PropTypes.array.isRequired
};
