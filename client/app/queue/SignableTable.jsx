import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { css } from 'glamor';

import Table from '../components/Table';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import ReaderLink from './ReaderLink';

import { sortTasks, renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';
import ApiUtil from '../util/ApiUtil';
import { LOGO_COLORS } from '../constants/AppConstants';
import { CATEGORIES } from './constants';
import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { WarningSymbol } from '../components/RenderFunctions';

const subHeadStyle = css({
  fontSize: 'small',
  color: COMMON_COLORS.GREY_MEDIUM
});

class ReviewableTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];
    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  veteranIsAppellant = (task) => _.isNull(this.getAppealForTask(task, 'appellant_full_name'));

  getCaseDetailsLink = (task) => <React.Fragment>
    {!task.attributes.task_id && <WarningSymbol />}
    <Link to={`/tasks/${task.vacolsId}`} disabled={!task.attributes.task_id}>
      {this.getAppealForTask(task, 'veteran_full_name')} ({this.getAppealForTask(task, 'vbms_id')})
    </Link>
    {!this.veteranIsAppellant(task) && <React.Fragment>
      <br />
      <span {...subHeadStyle}>Veteran is not the appellant</span>
    </React.Fragment>}
  </React.Fragment>;

  getQueueColumns = () => [
    {
      header: 'Case Details',
      valueFunction: this.getCaseDetailsLink
    },
    {
      header: 'Type(s)',
      valueFunction: (task) => renderAppealType(this.getAppealForTask(task))
    },
    {
      header: 'Docket Number',
      valueFunction: (task) => this.getAppealForTask(task, 'docket_number')
    },
    {
      header: 'Issues',
      valueFunction: (task) => this.getAppealForTask(task, 'issues.length')
    }
  ];

  render = () => {
    const tasks = sortTasks(_.pick(this.props, 'tasks', 'appeals'));
    const reviewableTasks = [];
    for (const k in tasks) {
      if (tasks[k].attributes.task_type === 'Review') {
        reviewableTasks.push(tasks[k]);
      }
    }
    return <Table
      columns={this.getQueueColumns}
      rowObjects={reviewableTasks}
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

ReviewableTable.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

export default connect(mapStateToProps)(ReviewableTable);
