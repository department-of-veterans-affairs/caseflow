import React from 'react';
import PropTypes from 'prop-types';
import Table from '../components/Table';
import moment from 'moment';
import Link from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Link';

export default class QueueTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.attributes.vacols_id;

  getQueueColumns = () => [
    {
      header: 'Decision Task Details',
      valueFunction: (appeal) => <Link>
        {appeal.attributes.veteran_full_name} ({appeal.attributes.vacols_id})
      </Link>
    },
    {
      header: 'Type(s)',
      // todo: highlight AOD in red
      valueFunction: (appeal) => appeal.attributes.type
    },
    {
      header: 'Docket Number',
      valueFunction: (appeal) => appeal.attributes.docket_number
    },
    {
      header: 'Issues',
      valueFunction: (appeal) => appeal.attributes.issues.length
    },
    {
      header: 'Due Date',
      valueFunction: (appeal) => appeal.tasks.length ?
        moment(appeal.tasks[0].attributes.due_on).format('MM/DD/YY') : ''
    },
    {
      header: 'Reader Documents',
      valueFunction: (appeal) => {
        // todo: get document count
        return <Link href={`/reader/appeal/${appeal.attributes.vacols_id}/documents`}>
          <span style={{ color: 'red' }}>FAKE ###</span>
        </Link>;
      }
    }
  ];

  render() {
    return <Table
      columns={this.getQueueColumns}
      rowObjects={this.props.appeals}
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

QueueTable.propTypes = {
  tasks: PropTypes.arrayOf(PropTypes.object).isRequired,
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired
};
