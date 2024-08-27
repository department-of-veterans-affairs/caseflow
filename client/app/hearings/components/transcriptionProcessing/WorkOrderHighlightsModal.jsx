import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../../COPY';
import ApiUtil from 'app/util/ApiUtil';
import Modal from '../../../components/Modal';

const WorkOrderHightlightsModal = ({ onCancel, workOrder }) => {
  const [items, setItems] = useState([{ docketNumber: '123456789', caseDetails: 'John Doe' }]);

  const renderItems = () => {
    return items.map((item, index) =>
      <tr>
        <td>{index + 1}</td>
        <td>{item.docketNumber}</td>
        <td>{item.caseDetails}</td>
      </tr>
    );
  };

  const renderList = () => {
    return (
      <table>
        <tr>
          <th></th>
          <th>{COPY.TABLE_DOCKET_NUMBER}</th>
          <th>{COPY.TRANSCRIPTION_FILE_DISPATCH_CASE_DETAILS_COLUMN_NAME}</th>
        </tr>
        {renderItems(items)}
      </table>
    );
  };

  return (
    <Modal
      title={`Order contents of work order ${workOrder}`}
      buttons={[
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: COPY.MODAL_CLOSE_BUTTON,
          onClick: onCancel
        }
      ]}
      closeHandler={onCancel}
    >
      <p>There are ({items.length}) appeals in this task order:</p>
      {renderList()}
    </Modal>
  );
};

WorkOrderHightlightsModal.propTypes = {
  onCancel: PropTypes.func,
  workOrder: PropTypes.string
};

export default WorkOrderHightlightsModal;

