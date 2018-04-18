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
import CaseDetailsLink from './CaseDetailsLink';

import { setAppealDocCount, loadAppealDocCountFail } from './QueueActions';
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

class AttorneyTaskTable extends React.PureComponent {
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
      header: 'Due Date',
      valueFunction: (task) => <DateString date={task.attributes.due_on} />
    },
    {
      header: 'Reader Documents',
      valueFunction: (task) => {

      // TODO: We should use ReaderLink instead of Link as the loading component child.
        const redirectUrl = encodeURIComponent(window.location.pathname);
        const href = `/reader/appeal/${task.vacolsId}/documents?queue_redirect_url=${redirectUrl}`;

        return <LoadingDataDisplay
          createLoadPromise={this.createLoadPromise(task)}
          errorComponent="span"
          failStatusMessageChildren={<ReaderLink vacolsId={task.vacolsId} />}
          loadingComponent={SmallLoader}
          loadingComponentProps={{
            message: 'Loading...',
            spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
            component: Link,
            componentProps: {
              href
            }
          }}>
          <ReaderLink vacolsId={task.vacolsId}
            analyticsSource={CATEGORIES.QUEUE_TABLE}
            redirectUrl={window.location.pathname} />
        </LoadingDataDisplay>;
      }
    }
  ];

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
      then((response) => {
        const resp = JSON.parse(response.text);
        const docCount = resp.data.attributes.documents.length;

        this.props.setAppealDocCount(
          task.vacolsId,
          docCount
        );
      }, () => this.props.loadAppealDocCountFail(task.vacolsId));
  };

  render = () => <Table
    columns={this.getQueueColumns}
    rowObjects={sortTasks(_.pick(this.props, 'tasks', 'appeals'))}
    getKeyForRow={this.getKeyForRow}
  />;
}

AttorneyTaskTable.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount,
  loadAppealDocCountFail
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AttorneyTaskTable);
