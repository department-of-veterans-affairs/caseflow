import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import Table from '../components/Table';
import moment from 'moment';
import Link from '../components/Link';
import Highlight from '../components/Highlight';

export const getRowObjects = ({ appeals, tasks }) => {
  return appeals.reduce((acc, appeal) => {
    // todo: Attorneys currently only have one task per appeal, but future users might have multiple
    appeal.tasks = tasks.filter((task) => task.attributes.appeal_id === appeal.attributes.vacols_id);

    acc.push(appeal);

    return acc;
  }, []);
};

class QueueTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.attributes.vacols_id;

  highlightWrapper = (children = '') => <Highlight searchQuery="filterCriteria.searchQuery">{children}</Highlight>

  getQueueColumns = () => {
    return [
      {
        cellClass: '',
        header: 'Decision Task Details',
        valueFunction: (appeal) => <Link>
          {this.highlightWrapper(`${appeal.attributes.veteran_full_name} (${appeal.attributes.vacols_id})`)}
        </Link>
      },
      {
        cellClass: '',
        header: 'Type(s)',
        // todo: highlight AOD in red
        valueFunction: (appeal) => <span>
          {this.highlightWrapper(appeal.attributes.type)}
        </span>
      },
      {
        cellClass: '',
        header: 'Docket Number',
        valueFunction: (appeal) => <span>
          {this.highlightWrapper(appeal.attributes.docket_number)}
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
  };

  render() {
    const rowObjects = getRowObjects(this.props);

    return <div>
      <Table
        columns={this.getQueueColumns}
        rowObjects={rowObjects}
        summary="Your Tasks"
        className="queue-tasks-table"
        getKeyForRow={this.getKeyForRow}
      />
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({}, dispatch)
);

export default connect(null, mapDispatchToProps)(QueueTable);

QueueTable.propTypes = {
  tasks: PropTypes.arrayOf(PropTypes.object).isRequired,
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired
};
