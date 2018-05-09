import CaseDetailsLink from './CaseDetailsLink';
import PropTypes from 'prop-types';
import React from 'react';
import Table from '../components/Table';
import _ from 'lodash';
import moment from 'moment';
import { connect } from 'react-redux';
import { renderAppealType } from './utils';
import AppealDocumentCount from './AppealDocumentCount';

class JudgeAssignTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, { task }) => task.id;

  getCaseDetailsLink = ({ task, appeal }) => <CaseDetailsLink task={task} appeal={appeal} />;

  getQueueColumns = () => [
    {
      header: 'Case Details',
      valueFunction: this.getCaseDetailsLink
    },
    {
      header: 'Type(s)',
      valueFunction: ({ appeal }) => renderAppealType(appeal)
    },
    {
      header: 'Docket Number',
      valueFunction: ({ appeal }) => _.get(appeal.attributes, 'docket_number')
    },
    {
      header: 'Issues',
      valueFunction: ({ appeal }) => _.get(appeal.attributes, 'issues.length')
    },
    {
      header: 'Docs in Claims Folder',
      valueFunction: ({ appeal }) => <AppealDocumentCount appeal={appeal} />
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
      rowObjects={this.props.tasksAndAppeals}
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

JudgeAssignTaskTable.propTypes = {
  tasksAndAppeals: PropTypes.array.isRequired
};

const mapStateToProps = () => ({});

export default connect(mapStateToProps)(JudgeAssignTaskTable);
