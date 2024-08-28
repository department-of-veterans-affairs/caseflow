import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../../COPY';
import ApiUtil from 'app/util/ApiUtil';
import Modal from '../../../components/Modal';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { css } from 'glamor';
import DocketTypeBadge from '../../../components/DocketTypeBadge';

const WorkOrderHightlightsModal = ({ onCancel, workOrder }) => {
  const [items, setItems] = useState([]);

  const styles = {
    headerStyle: {
      fontWeight: 'bold'
    },
    tableBody: {
      margin: 'auto',
      width: '100%',
    }
  };

  const tableStyles = css({
    '& th': {
      border: 'none',
      borderBottom: '1px solid',
      borderColor: COLORS.GREY_LIGHT
    },
    '& td': {
      border: 'none',
      borderBottom: '1px solid',
      borderColor: COLORS.GREY_LIGHT
    }
  });

  const renderItems = () => {
    return items.map((item, index) =>
      <tr key={index}>
        <td>{index + 1}</td>
        <td><DocketTypeBadge name={item.hearing_type} number={index} />{item.docket_number}</td>
        <td><a href={`/queue/appeals/${item.appeal_id}`}>{item.case_details}</a></td>
      </tr>
    );
  };

  const renderList = () => {
    return (
      <table {...tableStyles} style={styles.tableBody}>
        <tr>
          <th></th>
          <th style={styles.headerStyle}>{COPY.TABLE_DOCKET_NUMBER}</th>
          <th style={styles.headerStyle}>{COPY.TRANSCRIPTION_FILE_DISPATCH_CASE_DETAILS_COLUMN_NAME}</th>
        </tr>
        {renderItems(items)}
      </table>
    );
  };

  const fetchWorkOrderContent = () => {
    ApiUtil.get(`transcription_work_order/display_wo_contents?task_number=${workOrder}`).
      then((response) => setItems(response.body?.data));
  };

  useEffect(() => {
    fetchWorkOrderContent();
  }, []);

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
      noDivider
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

