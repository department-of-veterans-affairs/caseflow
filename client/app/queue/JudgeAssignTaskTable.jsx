import CaseDetailsLink from './CaseDetailsLink';
import PropTypes from 'prop-types';
import React from 'react';
import Table from '../components/Table';
import _ from 'lodash';
import moment from 'moment';
import { connect } from 'react-redux';
import { sortTasks, renderAppealType } from './utils';
import AppealDocumentCount from './AppealDocumentCount';

class JudgeAssignTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, { task }) => task.id;

  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  getCaseDetailsLink = ({ task }) => <CaseDetailsLink task={task} appeal={this.getAppealForTask(task)} />;

  getQueueColumns = () => [
    {
      header: 'Case Details',
      valueFunction: this.getCaseDetailsLink
    },
    {
      header: 'Type(s)',
      valueFunction: ({ task }) => renderAppealType(this.getAppealForTask(task))
    },
    {
      header: 'Docket Number',
      valueFunction: ({ task }) => this.getAppealForTask(task, 'docket_number')
    },
    {
      header: 'Issues',
      valueFunction: ({ task }) => this.getAppealForTask(task, 'issues.length')
    },
    {
      header: 'Docs in Claims Folder',
      valueFunction: ({ task }) => {
        return <AppealDocumentCount appeal={this.getAppealForTask(task)} />;
      }
    },
    {
      header: 'Days Waiting',
      valueFunction: ({ task }) => (
        moment().
          startOf('day').
          diff(moment(task.attributes.assigned_on), 'days'))
    }
  ];

  render = () => {
    return <Table
      columns={this.getQueueColumns}
      rowObjects={
        sortTasks(
          _.pick(this.props, 'tasks', 'appeals')).
          filter(
            (task) => task.attributes.task_type === 'Assign').
          map((task) => ({
            task,
            appeal: this.getAppealForTask(task) }))
      }
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

JudgeAssignTaskTable.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

export default connect(mapStateToProps)(JudgeAssignTaskTable);
