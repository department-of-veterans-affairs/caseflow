import React from 'react';
import { css } from 'glamor';
import QueueTable from '../../../queue/QueueTable';
import PropTypes from 'prop-types';
import QUEUE_CONFIG from '../../../../constants/QUEUE_CONFIG.json';

const tableNumberStyling = css({
  '& tr > td:first-child': {
    paddingRight: 0
  },
  '& td:nth-child(2)': {
    paddingLeft: 0
  }
});

class AssignHearingsTable extends React.Component {
  getPaginationProps = () => {
    const { user, tabName, enablePagination } = this.props;

    if (!enablePagination) {
      return {};
    }

    const endpoint = `/organizations/hearings-management/task_pages?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=${tabName}&filter[]=col=${QUEUE_CONFIG.REGIONAL_OFFICE_KEY_COLUMN}%26val=C`;

    return {
      useTaskPagesApi: true,
      taskPagesApiEndpoint: endpoint,
      casesPerPage: 5,
      enablePagination: true,
      eager: true,
      rowObjects: []
    };
  };

  render () {
    let { columns, rowObjects, tabName } = this.props;

    return (
      <QueueTable
        columns={columns}
        rowObjects={rowObjects}
        key={tabName}
        summary="scheduled-hearings-table"
        slowReRendersAreOk
        bodyStyling={tableNumberStyling}
        {...this.getPaginationProps()}
      />
    );
  }
}

AssignHearingsTable.propTypes = {
  user: PropTypes.object,
  columns: PropTypes.array,
  rowObjects: PropTypes.array,
  tabName: PropTypes.string,
  enablePagination: PropTypes.bool
};

export default AssignHearingsTable;
