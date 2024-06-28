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
            <th className="corr-table-borderless-first-item"><strong>Package Document Type</strong></th>
            <th><strong>VA DOR</strong></th>
            <th><strong>Veteran</strong></th>
            <th className="corr-table-borderless-last-item"><strong>Correspondence Type</strong></th>
          </tr>
          <tr>
            <td className="corr-table-borderless-first-item">
              {props.correspondence.nod ? 'NOD' : 'Non-NOD'}
            </td>
            <td>{moment(props.correspondence.vaDateOfReceipt).format('MM/DD/YYYY')}</td>
            <td>{props.correspondence.veteranFullName} ({props.correspondence.veteranFileNumber})</td>
            <td className="corr-table-borderless-last-item">{props.correspondence.correspondenceType}</td>
          </tr>
          <tr>
            <th colSpan={6} className="corr-table-borderless-first-item corr-table-borderless-last-item">
              <strong>Notes</strong></th>
          </tr>
          <tr>
            <td colSpan={6} className="corr-table-borderless-first-item corr-table-borderless-last-item">
              {props.correspondence.notes}</td>
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

