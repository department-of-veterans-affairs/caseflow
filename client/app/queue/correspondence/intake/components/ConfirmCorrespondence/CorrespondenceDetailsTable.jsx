import React from 'react';
import moment from 'moment';
import { useSelector } from 'react-redux';

export const CorrespondenceDetailsTable = () => {

  const currentCorrespondence = useSelector((state) => state.intakeCorrespondence.currentCorrespondence);
  const veteranInformation = useSelector((state) => state.intakeCorrespondence.veteranInformation);

  return (
    <div>
      <h2 className="corr-h2">About the Correspondence</h2>
      <table className="corr-table-borderless">
        <tbody>
          <tr>
            <th><strong>Portal Entry Date</strong></th>
            <th><strong>Source Type</strong></th>
            <th><strong>Package Document Type</strong></th>
            <th><strong>CM Packet Number</strong></th>
            <th><strong>CMP Queue Name</strong></th>
            <th><strong>VA DOR</strong></th>
          </tr>
          <tr>
            <td>{moment(currentCorrespondence.portal_entry_date).format('MM/DD/YYYY')}</td>
            <td>{currentCorrespondence.source_type}</td>
            <td>{currentCorrespondence.package_document_type_id}</td>
            <td>{currentCorrespondence.cmp_packet_number}</td>
            <td>{currentCorrespondence.cmp_queue_id}</td>
            <td>{moment(currentCorrespondence.va_date_of_receipt).format('MM/DD/YYYY')}</td>
          </tr>
          <tr>
            <th colSpan={2}><strong>Veteran</strong></th>
            <th><strong>Correspondence Type</strong></th>
          </tr>
          <tr>
            <td colSpan={2}>
              {veteranInformation.first_name} {veteranInformation.last_name} ({veteranInformation.file_number})
            </td>
            <td>{currentCorrespondence.correspondence_type_id}</td>
          </tr>
          <tr>
            <th colSpan={6}><strong>Notes</strong></th>
          </tr>
          <tr>
            <td colSpan={6}>{currentCorrespondence.notes}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

export default CorrespondenceDetailsTable;
