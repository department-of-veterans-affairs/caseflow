import React from 'react';
import { withRouter } from 'react-router-dom';
import { LOGO_COLORS } from '../../constants/AppConstants';
import QueueTable from '../QueueTable';
import PropTypes from 'prop-types';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import WindowUtil from '../../util/WindowUtil';

class ListCorrespondenceTable extends React.Component {

  render() {

    const testobj = {
      veterandetails: 'Rosalie Turner',
      packagedocumenttype: '12345678',
      cmpacketnumber: '12345679'
    };

    const columns = [
      {
        name: 'veterandetails',
        header: 'Veteran Details',
        align: 'left',
        valueName: 'veterandetails',
        getSortValue: (row) => row.veterandetails
      },
      {
        name: 'packagedocumenttype',
        header: 'Package Document Type ',
        align: 'left',
        valueName: 'packagedocumenttype',
        enableFilter: true
      },
      {
        name: 'cmpacketnumber',
        header: 'CM Packet Number ',
        align: 'left',
        valueName: 'cmpacketnumber'
      }
    ];
    const tabPaginationOptions = {
      onPageLoaded: this.onPageLoaded
    };

    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load the correspondence cases list.<br />
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
    </div>;

    return (
      <QueueTable
        className="assign-correspondence-table"
        columns={columns}
        rowObjects={[testobj]}
        // key={tabName}
        summary="scheduled-hearings-table"
        // slowReRendersAreOk
        // bodyStyling={tableNumberStyling}
        useTaskPagesApi
        taskPagesApiEndpoint= "/queue/correspondence"
        enablePagination
        // tabPaginationOptions={tabPaginationOptions}
        // styling={docketStyle}
      />
    );
  }
}

ListCorrespondenceTable.propTypes = {
  hearingScheduleColumns: PropTypes.array,
  hearingScheduleRows: PropTypes.array,
  onApply: PropTypes.func,
  history: PropTypes.object,
  user: PropTypes.shape({
    userCanBuildHearingSchedule: PropTypes.bool
  })
};

export default ListCorrespondenceTable;
