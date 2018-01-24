import React from 'react';
import PropTypes from 'prop-types';
import Table from '../components/Table';
import moment from 'moment';
import Link from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Link';
import { css } from 'glamor';
import { sortTasks } from './utils';

// 'red' isn't contrasty enough w/white, raises Sniffybara::PageNotAccessibleError when testing
const redText = css({ color: '#E60000' });

export default class QueueTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  getQueueColumns = () => [
    {
      header: 'Decision Task Details',
      valueFunction: (task) => <Link>
        {task.appeal.attributes.veteran_full_name} ({task.appeal.attributes.vacols_id})
      </Link>
    },
    {
      header: 'Type(s)',
      valueFunction: (task) => {
        const {
          attributes: { aod, type }
        } = task.appeal;
        const cavc = type === 'Court Remand';
        const valueToRender = <div>
          {aod && <span><span {...redText}>AOD</span>, </span>}
          {cavc && <span><span {...redText}>CAVC</span>, </span>}
          <span>{type}</span>
        </div>;

        return <div>{valueToRender}</div>;
      }
    },
    {
      header: 'Docket Number',
      valueFunction: (task) => task.appeal.attributes.docket_number
    },
    {
      header: 'Issues',
      valueFunction: (task) => task.appeal.attributes.issues.length
    },
    {
      header: 'Due Date',
      valueFunction: (task) => moment(task.attributes.due_on).format('MM/DD/YY')
    },
    {
      header: 'Reader Documents',
      valueFunction: (task) => {
        // todo: get document count
        return <Link href={`/reader/appeal/${task.appeal.attributes.vacols_id}/documents`}>
          <span {...redText}>FAKE ###</span>
        </Link>;
      }
    }
  ];

  render = () => <Table
    columns={this.getQueueColumns}
    rowObjects={sortTasks(this.props.tasks)}
    getKeyForRow={this.getKeyForRow}
  />;
}

QueueTable.propTypes = {
  tasks: PropTypes.arrayOf(PropTypes.object).isRequired,
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired
};
