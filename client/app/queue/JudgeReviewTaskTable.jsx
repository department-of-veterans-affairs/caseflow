import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import moment from 'moment';

import Table from '../components/Table';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import ReaderLink from './ReaderLink';
import CaseDetailsLink from './CaseDetailsLink';

import { sortTasks, renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';
import ApiUtil from '../util/ApiUtil';
import { LOGO_COLORS } from '../constants/AppConstants';
import { CATEGORIES } from './constants';
import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

class JudgeReviewTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];
    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  getCaseDetailsLink = (task) => <CaseDetailsLink task={task} appeal={this.getAppealForTask(task)} />;

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
    },
    {
      header: 'Days Waiting',
      valueFunction: (task) => moment().startOf('day').diff(moment(task.attributes.assigned_on), 'days')
    }
  ];

  render = () => {
    return <Table
      columns={this.getQueueColumns}
      rowObjects={
        sortTasks(
          _.pick(this.props, 'tasks', 'appeals')
        ).filter(t => t.attributes.task_type === 'Review')
      }
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

JudgeReviewTaskTable.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

export default connect(mapStateToProps)(JudgeReviewTaskTable);
