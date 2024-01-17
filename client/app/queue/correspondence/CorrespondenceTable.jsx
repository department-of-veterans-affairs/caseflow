import React from 'react';
import QueueTable from '../QueueTable';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class CorrespondenceTable extends React.Component {

  render() {

    const columns = [
      {
        name: 'veteranDetails',
        header: 'Veteran Details',
        align: 'left',
        valueName: 'veteranDetails',
        getSortValue: (row) => row.firstName,
        backendCanSort: true,
        valueFunction: (row) => (
          <Link href={`/queue/correspondence/${row.correspondenceUuid}/review_package`}>
            {`${row.firstName} ${row.lastName} (${row.fileNumber})`}
          </Link>
        )
      },
      {
        name: 'packageDocumentType',
        header: 'Package Document Type ',
        align: 'left',
        valueName: 'packageDocumentType',
        enableFilter: true,
        label: 'package-document-type-filter',
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
        rowObjects={this.props.vetCorrespondences}
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
  loadVetCorrespondence: PropTypes.func,
  vetCorrespondences: PropTypes.array,
  history: PropTypes.object,
  user: PropTypes.shape({
    userCanBuildHearingSchedule: PropTypes.bool
  })
};

export default CorrespondenceTable;
