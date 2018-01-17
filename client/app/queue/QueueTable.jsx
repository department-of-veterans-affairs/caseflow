import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import Table from '../components/Table';
import moment from 'moment';
import Link from '../components/Link';

export const getRowObjects = ({ appeals, tasks }) => {
  return appeals.reduce((acc, appeal) => {
    // todo: Attorneys currently only have one task per appeal, but future users might have multiple
    appeal.tasks = tasks.filter((task) => task.attributes.vacols_id === appeal.attributes.appeal_id);

    acc.push(appeal);

    return acc;
  }, []);
};

class QueueTable extends React.Component {
  getKeyForRow = (rowNumber, object) => object.id;

  getQueueColumns = () => {
    return [
      {
        cellClass: '',
        header: 'Decision Task Details',
        valueFunction: (appeal) => {
          const vetName = appeal.tasks.length ? appeal.tasks[0].attributes.veteran_full_name : 'N/A';

          return <Link>
            {`${vetName} (${appeal.attributes.appeal_id})`}
          </Link>;
        }
      },
      {
        cellClass: '',
        header: 'Type(s)',
        valueFunction: _.noop
      },
      {
        cellClass: '',
        header: 'Docket Number',
        valueFunction: _.noop
      },
      {
        cellClass: '',
        header: 'Issues',
        valueFunction: (appeal) => <span>
          {appeal.tasks.length ? appeal.tasks[0].attributes.issues.length : 0}
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
          return <a href={`/reader/appeal/${appeal.attributes.appeal_id}/documents`}>
            {_.random(1, 100)}
          </a>
        }
      },
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

const mapStateToProps = (state, props) => ({});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({}, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(QueueTable);

QueueTable.propTypes = {
  tasks: PropTypes.arrayOf(PropTypes.object).isRequired,
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired,
};
