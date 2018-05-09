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
import { renderAppealType } from './utils';

class JudgeAssignTaskTable extends React.PureComponent {
  getKeyForRow = (rowNumber, { task }) => task.id;

  getCaseDetailsLink = ({ task, appeal }) => <CaseDetailsLink task={task} appeal={appeal} />;

  createLoadPromise = ({ task, appeal }) => () => {
    if (!_.isUndefined(_.get(appeal.attributes, 'docCount'))) {
      return Promise.resolve();
    }

    const url = _.get(appeal.attributes, 'number_of_documents_url');
    const vbmsId = _.get(appeal.attributes, 'vbms_id');
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
      valueFunction: ({ task, appeal }) => {
        return <LoadingDataDisplay
          createLoadPromise={this.createLoadPromise({ task,
            appeal })}
          errorComponent="span"
          failStatusMessageProps={{ title: 'Unknown failure' }}
          failStatusMessageChildren={<span>?</span>}
          loadingComponent={SmallLoader}
          loadingComponentProps={{
            message: 'Loading...',
            spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
            component: 'span'
          }}>
          {_.get(appeal.attributes, 'docCount')}
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
      rowObjects={this.props.tasksAndAppeals}
      getKeyForRow={this.getKeyForRow}
    />;
  }
}

JudgeAssignTaskTable.propTypes = {
  tasksAndAppeals: PropTypes.array.isRequired
};

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount,
  loadAppealDocCountFail
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskTable);
