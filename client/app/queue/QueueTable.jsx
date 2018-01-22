import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import Table from '../components/Table';
import moment from 'moment';
import Link from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Link';

export default class QueueTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.attributes.vacols_id;

  getQueueColumns = () => [
    {
      cellClass: '',
      header: 'Decision Task Details',
      valueFunction: (appeal) => <Link>
        {appeal.attributes.veteran_full_name} ({appeal.attributes.vacols_id})
      </Link>
    },
    {
      cellClass: '',
      header: 'Type(s)',
      // todo: highlight AOD in red
      valueFunction: (appeal) => <span>
        {appeal.attributes.type}
      </span>
    },
    {
      cellClass: '',
      header: 'Docket Number',
      valueFunction: (appeal) => <span>
        {appeal.attributes.docket_number}
      </span>
    },
    {
      cellClass: '',
      header: 'Issues',
      valueFunction: (appeal) => <span>
        {appeal.attributes.issues.length}
      </span>
    },
    {
      cellClass: '',
      header: 'Due Date',
      valueFunction: (appeal) => <span>
        {appeal.tasks.length ? moment(appeal.tasks[0].attributes.due_on).format('MM/DD/YY') : ''}
      </span>
    },
    {
      cellClass: '',
      header: 'Reader Documents',
      valueFunction: (appeal) => {
        return <a href={`/reader/appeal/${appeal.attributes.vacols_id}/documents`}>
          {(_.random(1, 2000)).toLocaleString()}
        </a>;
      }
    }
  ];

  render() {
    return <Table
      columns={this.getQueueColumns}
      rowObjects={this.props.appeals}
      summary="Your Tasks"
      className="queue-tasks-table"
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

QueueTable.propTypes = {
  tasks: PropTypes.arrayOf(PropTypes.object).isRequired,
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired
};
