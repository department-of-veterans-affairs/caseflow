import React from 'react';
import QueueTable from '../QueueTable';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class CorrespondenceTable extends React.Component {

  render() {
    const testobj = [{

      veteranDetails: 'Rosalie Turner (123456789)',
      packageDocumentType: '1111111',
      cmPacketNumber: '22222222',
      correspondeceId: 11,
    },
    {
      veteranDetails: 'Ana Turner (123456789)',
      packageDocumentType: '12345678',
      cmPacketNumber: '12345679',
      correspondeceId: 2,
    }];

    const columns = [
      {
        name: 'veteranDetails',
        header: 'Veteran Details',
        align: 'left',
        valueName: 'veteranDetails',
        getSortValue: (row) => row.veteranDetails,
        backendCanSort: true,
        valueFunction: (row) => (
          <Link href={`/queue/correspondence/${row.correspondeceId}/review_package`}>
            {row.veteranDetails}
          </Link>
        )
      },
      {
        name: 'packageDocumentType',
        header: 'Package Document Type ',
        align: 'left',
        valueName: 'packageDocumentType',
        enableFilter: true,
        getSortValue: (row) => row.packageDocumentType,
        backendCanSort: true
      },
      {
        name: 'cmPacketNumber',
        header: 'CM Packet Number ',
        align: 'left',
        valueName: 'cmPacketNumber',
        getSortValue: (row) => row.cmPacketNumber,
        backendCanSort: true
      }
    ];
    const tabPaginationOptions = {
      onPageLoaded: this.onPageLoaded
    };

    return (
      <QueueTable
        className="assign-correspondence-table"
        columns={columns}
        rowObjects={testobj}
        summary="scheduled-hearings-table"
        enablePagination
        tabPaginationOptions={tabPaginationOptions}
      />
    );
  }
}

CorrespondenceTable.propTypes = {
  hearingScheduleColumns: PropTypes.array,
  hearingScheduleRows: PropTypes.array,
  onApply: PropTypes.func,
  history: PropTypes.object,
  user: PropTypes.shape({
    userCanBuildHearingSchedule: PropTypes.bool
  })
};

export default CorrespondenceTable;
