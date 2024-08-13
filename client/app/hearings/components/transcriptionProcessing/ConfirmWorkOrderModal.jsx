import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../../COPY';
import ApiUtil from 'app/util/ApiUtil';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import Button from '../../../components/Button';
import { Link } from 'react-router-dom/cjs/react-router-dom.min';
import { css } from 'glamor';

const ConfirmWorkOrderModal = ({ history, onCancel }) => {
  const { state } = history.location;

  const styles = {
    body: {
      border: 'solid 2px',
      borderColor: COLORS.GREY_LIGHT,
      margin: '3rem'
    },
    buttonSection: {
      display: 'flex',
      justifyContent: 'space-between',
      marginRight: '3rem',
    },
    formInfoSection: {
      listStyleType: 'none',
      marginTop: '-3rem',
    }
  };

  const marginStyles = css({
    '& h1': {
      margin: '3rem'
    },
    '& button': {
      margin: '2rem'
    },
    '& a': {
      margin: '3rem'
    },
    '& h4': {
      margin: '3rem',
      fontSize: '17px'
    },
    '& p': {
      marginTop: '2.9rem',
      marginLeft: '-2rem'
    },
    '& li': {
      display: 'inline-flex',
      marginBottom: '-4rem'
    },
    '& ul': {
      display: 'inline-grid',
      marginLeft: '-3rem'
    }
  });

  const renderFormInformation = () => {
    return (
      <ul style={styles.formInfoSection}>
        <li><h4>Work Order:</h4><p>{state?.workOrder}</p></li>
        <li><h4>Return date:</h4><p>{state?.returnDateValue}</p></li>
        <li><h4>Contractor:</h4><p>{state?.contractor?.name}</p></li>
      </ul>
    );
  };

  const cancelWorkOrder = (files) => {
    const ids = files.map((file) => file.id);
    const data = {
      file_ids: ids,
      status: false
    };

    ApiUtil.post('/hearings/transcription_files/lock', { data });
    onCancel();
  };

  const renderButtonSection = () => {
    return (
      <div style={styles.buttonSection}>
        <Link onClick={() => cancelWorkOrder(state?.selectedFiles)}>Cancel</Link>
        <div>
          <Button
            classNames={['usa-button', 'usa-button-secondary']}
            onClick={onCancel}
          >
            {COPY.TRANSCRIPTION_TABLE_MODIFY_WORK_ORDER}
          </Button>
          <Button>{COPY.TRANSCRIPTION_TABLE_DISPATCH_WORK_ORDER}</Button>
        </div>
      </div>
    );
  };

  return (
    <div {...marginStyles} style={styles.body}>
      <h1>Confirm work order summary</h1>
      {renderFormInformation()}
      {renderButtonSection()}
    </div>
  );
};

ConfirmWorkOrderModal.propTypes = {
  history: PropTypes.object,
  onCancel: PropTypes.func,
};

export default ConfirmWorkOrderModal;
