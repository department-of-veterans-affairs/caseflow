import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';

import Table from '../components/Table';
import ReaderLink from './ReaderLink';
import CaseDetailsLink from './CaseDetailsLink';

import { renderAppealType } from './utils';
import { CATEGORIES, disabledLinkStyle } from './constants';
import COPY from '../../COPY.json';

class BeaamTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  getCaseDetailsLink = (appeal) =>
    <CaseDetailsLink task={{ vacolsId: appeal.attributes.vacolsId }} appeal={appeal} />;

  getQueueColumns = () => {
    const columns = [{
      header: COPY.CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE,
      valueFunction: this.getCaseDetailsLink
    }, {
      header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
      valueFunction: (appeal) => renderAppealType(appeal)
    }, {
      header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.attributes.docket_number
    }, {
      header: COPY.CASE_LIST_TABLE_APPEAL_ISSUE_COUNT_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.attributes.issues.length
    }, {
      header: COPY.CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE,
      valueFunction: (appeal) => {
        if (appeal.paper_case) {
          return <span {...disabledLinkStyle}>{COPY.ATTORNEY_QUEUE_TABLE_TASK_NO_DOCUMENTS_READER_LINK}</span>;
        }

        return <ReaderLink vacolsId={appeal.attributes.vacolsId}
          analyticsSource={CATEGORIES.QUEUE_TABLE}
          redirectUrl={window.location.pathname}
          appeal={appeal} />;
      }
    }];

    return columns;
  };

  render = () => <Table
    columns={this.getQueueColumns}
    rowObjects={_.values(this.props.appeals)}
    getKeyForRow={this.getKeyForRow}
  />;
}

BeaamTable.propTypes = {
  appeals: PropTypes.object.isRequired,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'appeals');

export default connect(mapStateToProps)(BeaamTable);
