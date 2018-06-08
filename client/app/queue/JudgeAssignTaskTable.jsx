import AppealDocumentCount from './AppealDocumentCount';
import COPY from '../../COPY.json';
import CaseDetailsLink from './CaseDetailsLink';
import Checkbox from '../components/Checkbox';
import PropTypes from 'prop-types';
import React from 'react';
import Table from '../components/Table';
import _ from 'lodash';
import moment from 'moment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { renderAppealType } from './utils';
import { setSelectionOfTaskOfUser } from './QueueActions';

class JudgeAssignTaskTable extends React.PureComponent {
  isVacolsIdSelected = (vacolsId) => {
    const isVacolsIdSelected = this.props.isVacolsIdAssignedToUserSelected[this.props.userId] || {};

    return isVacolsIdSelected[vacolsId] || false;
  }

  getKeyForRow = (rowNumber, { task }) => task.id;

  getCaseDetailsLink = ({ task, appeal }) => <CaseDetailsLink task={task} appeal={appeal} />;

  getQueueColumns = () => [
    {
      header: COPY.JUDGE_QUEUE_TABLE_SELECT_COLUMN_TITLE,
      valueFunction:
        ({ task }) => <Checkbox
          name={task.vacolsId}
          hideLabel
          value={this.isVacolsIdSelected(task.vacolsId)}
          onChange={
            (checked) =>
              this.props.setSelectionOfTaskOfUser(
                { userId: this.props.userId,
                  vacolsId: task.vacolsId,
                  selected: checked })} />
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
  tasksAndAppeals: PropTypes.array.isRequired,
  userId: PropTypes.string.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue, 'isVacolsIdAssignedToUserSelected');

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setSelectionOfTaskOfUser
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskTable);
