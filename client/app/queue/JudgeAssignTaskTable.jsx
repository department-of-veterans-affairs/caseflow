import ApiUtil from '../util/ApiUtil';
import CaseDetailsLink from './CaseDetailsLink';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import PropTypes from 'prop-types';
import React from 'react';
import SmallLoader from '../components/SmallLoader';
import Table from '../components/Table';
import _ from 'lodash';
import moment from 'moment';
import { LOGO_COLORS } from '../constants/AppConstants';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { setAppealDocCount, loadAppealDocCountFail } from './QueueActions';
import { sortTasks, renderAppealType } from './utils';

class JudgeAssignTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, { task }) => task.id;

  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  getCaseDetailsLink = ({ task }) => <CaseDetailsLink task={task} appeal={this.getAppealForTask(task)} />;

  getAppealForTask = (task, attr) => {
    const appeal = this.props.appeals[task.vacolsId];

    return attr ? _.get(appeal.attributes, attr) : appeal;
  };

  createLoadPromise = (task) => () => {
    if (!_.isUndefined(this.getAppealForTask(task, 'docCount'))) {
      return Promise.resolve();
    }

    const url = this.getAppealForTask(task, 'number_of_documents_url');
    const vbmsId = this.getAppealForTask(task, 'vbms_id');
    const requestOptions = {
      withCredentials: true,
      timeout: true,
      headers: { 'FILE-NUMBER': vbmsId }
    };

    return ApiUtil.get(url, requestOptions).
      then(
        (response) => {
          const resp = JSON.parse(response.text);
          const docCount = resp.data.attributes.documents.length;

          this.props.setAppealDocCount(
            task.vacolsId,
            docCount
          );
        },
        () => this.props.loadAppealDocCountFail(task.vacolsId));
  };

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
        return <LoadingDataDisplay
          createLoadPromise={this.createLoadPromise(task)}
          errorComponent="span"
          failStatusMessageProps={{ title: 'Unknown failure' }}
          failStatusMessageChildren={<span>?</span>}
          loadingComponent={SmallLoader}
          loadingComponentProps={{
            message: 'Loading...',
            spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
            component: 'span'
          }}>
          {this.getAppealForTask(task, 'docCount')}
        </LoadingDataDisplay>;
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
          map((task) => ({ task,
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

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount,
  loadAppealDocCountFail
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskTable);
