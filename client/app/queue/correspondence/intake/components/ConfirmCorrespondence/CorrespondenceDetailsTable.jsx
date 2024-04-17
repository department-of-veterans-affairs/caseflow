import React from 'react';
import moment from 'moment';
import PropTypes from 'prop-types';

export const CorrespondenceDetailsTable = (props) => {

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
            <td>{moment(props.correspondence.portalEntryDate).format('MM/DD/YYYY')}</td>
            <td>{props.correspondence.sourceType}</td>
            <td>{props.correspondence.packageDocumentType}</td>
            <td>{props.correspondence.cmpPacketNumber}</td>
            <td>{props.correspondence.cmpQueueId}</td>
            <td>{moment(props.correspondence.vaDateOfReceipt).format('MM/DD/YYYY')}</td>
          </tr>
          <tr>
            <th colSpan={2}><strong>Veteran</strong></th>
            <th><strong>Correspondence Type</strong></th>
          </tr>
          <tr>
            <td colSpan={2}>
              {props.correspondence.veteranFullName} ({props.correspondence.veteranFileNumber})
            </td>
            <td>{props.correspondence.correspondenceType}</td>
          </tr>
          <tr>
            <th colSpan={6}><strong>Notes</strong></th>
          </tr>
          <tr>
            <td colSpan={6}>{props.correspondence.notes}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

CorrespondenceDetailsTable.propTypes = {
  correspondence: PropTypes.object
};

export default CorrespondenceDetailsTable;
