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

    const endpoint = `/organizations/hearings-management/task_pages?${QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM}=${tabName}&filter[]=col%3D${QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN}%26val%3DRO17"`;

    return {
      useTaskPagesApi: true,
      taskPagesApiEndpoint: endpoint,
      casesPerPage: 25,
      enablePagination: true,
      eager: true,
      rowObjects: []
    };
  };

  render () {
    let { columns, rowObjects } = this.props;

    return (
      <QueueTable
        columns={columns}
        rowObjects={rowObjects}
        summary="scheduled-hearings-table"
        slowReRendersAreOk
        bodyStyling={tableNumberStyling}
<<<<<<< HEAD
        {...this.getPaginationProps()}
=======
>>>>>>> 3a5b22e1c98c64ca1f74514815ce422541c37af7
      />
    );
  }
}

AssignHearingsTable.propTypes = {
  user: PropTypes.object,
  columns: PropTypes.array,
<<<<<<< HEAD
  rowObjects: PropTypes.array,
  tabName: PropTypes.string,
  enablePagination: PropTypes.bool
=======
  rowObjects: PropTypes.array
>>>>>>> 3a5b22e1c98c64ca1f74514815ce422541c37af7
};

export default AssignHearingsTable;
