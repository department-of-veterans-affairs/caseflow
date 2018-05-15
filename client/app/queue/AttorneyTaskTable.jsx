import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';
import { css } from 'glamor';

import Table from '../components/Table';
import ReaderLink from './ReaderLink';
import CaseDetailsLink from './CaseDetailsLink';
import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';

import { sortTasks, renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';
import { CATEGORIES, redText } from './constants';
import COPY from '../../../COPY.json';

class AttorneyTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;
  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  getCaseDetailsLink = (task) => <CaseDetailsLink task={task} appeal={this.getAppealForTask(task)} />;

  tableStyle = css({
    '& > tr > td': {
      '&:last-of-type': {
        width: this.props.featureToggles.phase_two ? '25%' : ''
      }
    }
  });
  collapseColumnIfNoDASRecord = (task) => task.attributes.task_id ? 1 : 0;

  getQueueColumns = () => {
    const columns = [{
      header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
      valueFunction: this.getCaseDetailsLink
    }, {
      header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
      valueFunction: (task) => task.attributes.task_id ?
        renderAppealType(this.getAppealForTask(task)) :
        <span {...redText}>Please ask your judge to assign this case to you in DAS</span>,
      span: (task) => task.attributes.task_id ? 1 : 5
    }, {
      header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (task) => task.attributes.task_id ? this.getAppealForTask(task, 'docket_number') : null,
      span: this.collapseColumnIfNoDASRecord
    }, {
      header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
      valueFunction: (task) => task.attributes.task_id ? this.getAppealForTask(task, 'issues.length') : null,
      span: this.collapseColumnIfNoDASRecord
    }, {
      header: COPY.CASE_LIST_TABLE_DUE_DATE_COLUMN_TITLE,
      valueFunction: (task) => task.attributes.task_id ? <DateString date={task.attributes.due_on} /> : null,
      span: this.collapseColumnIfNoDASRecord
    }, {
      header: COPY.CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
      span: this.collapseColumnIfNoDASRecord,
      valueFunction: (task) => {
        if (!task.attributes.task_id) {
          return null;
        }

        return <ReaderLink vacolsId={task.vacolsId}
          analyticsSource={CATEGORIES.QUEUE_TABLE}
          redirectUrl={window.location.pathname}
          appeal={this.props.appeals[task.vacolsId]} />;
      }
    }];

    if (this.props.featureToggles.phase_two) {
      columns.push({
        header: COPY.CASE_LIST_TABLE_TASK_ACTION_COLUMN_TITLE,
        span: this.collapseColumnIfNoDASRecord,
        valueFunction: (task) => <SelectCheckoutFlowDropdown vacolsId={task.vacolsId} />
      });
    }

    return columns;
  };

  render = () => <Table
    columns={this.getQueueColumns}
    rowObjects={sortTasks(_.pick(this.props, 'tasks', 'appeals'))}
    getKeyForRow={this.getKeyForRow}
    rowClassNames={(task) => task.attributes.task_id ? null : 'usa-input-error'}
    bodyStyling={this.tableStyle}
  />;
}

AttorneyTaskTable.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

export default connect(mapStateToProps)(AttorneyTaskTable);
