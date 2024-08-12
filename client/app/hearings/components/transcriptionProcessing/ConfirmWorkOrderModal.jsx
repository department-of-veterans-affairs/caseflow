import React from "react";
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';
import ApiUtil from 'app/util/ApiUtil';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import Button from "../../../components/Button";
import { Link } from "react-router-dom/cjs/react-router-dom.min";

const ConfirmWorkOrderModal = ({ onCancel }) => {

  const styles = {
    body: {
      margin: '3rem',
      border: 'solid 2px',
      borderColor: COLORS.GREY_LIGHT
    },
    text: {
      margin: '3rem'
    },
    buttonSection: {
      display: 'flex'
    }
  };

  const renderButtonSection = () => {
    return (
      <div>
        <Link onClick={onCancel}>Cancel</Link>
      </div>
    );
  };

  return (
    <div style={styles.body}>
      <h1 style={styles.text}>Confirm work order summary</h1>
      {renderButtonSection()}
    </div>
  );
};

ConfirmWorkOrderModal.propTypes = {
  history: PropTypes.object,
  onCancel: PropTypes.func,
};

export default ConfirmWorkOrderModal;
