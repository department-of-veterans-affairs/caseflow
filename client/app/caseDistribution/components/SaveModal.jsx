
import React from 'react';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import { useSelector } from 'react-redux';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { findOption } from '../utils';
import { changedLevers } from '../reducers/levers/leversSelector';

export const SaveModal = (props) => {
  const { setShowModal, handleConfirmButton } = props;

  const theState = useSelector((state) => state);

  const leverValueDisplay = (lever) => {
    const doesDatatypeRequireComplexLogic = (lever.data_type === ACD_LEVERS.data_types.radio ||
      lever.data_type === ACD_LEVERS.data_types.combination);

    if (doesDatatypeRequireComplexLogic) {
      const selectedOption = findOption(lever, lever.value);
      const isSelectedOptionANumber = selectedOption.data_type === ACD_LEVERS.data_types.number;

      return isSelectedOptionANumber ? selectedOption.value : selectedOption.text;
    }

    return <strong>{lever.value}</strong>;
  };

  const leverList = () => {
    const updatedLevers = changedLevers(theState);

    return (
      <div>
        <table>
          <tbody>
            <tr>
              <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableLeftStyling}`}>
                {COPY.ASE_DISTRIBUTION_LEVER_SAVE_BUTTON_DATA}
              </th>
              <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableRightStyling}`}>
                {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_PREV_VALUE}
              </th>
              <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableRightStyling}`}>
                {COPY.CASE_DISTRIBUTION_LEVER_SAVE_BUTTON_VALUE}
              </th>
            </tr>
          </tbody>
          <tbody>
            {updatedLevers.map((lever, index) => (
              <tr key={index}>
                <React.Fragment>
                  <td className={`${styles.modalTableStyling} ${styles.modalTableLeftStyling}`}>{lever.title}</td>
                  <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}>
                    {lever.backendValue}
                  </td>
                  <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}>
                    {leverValueDisplay(lever)}
                  </td>
                </React.Fragment>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  };

  return (
    <Modal
      isOpen
      onClose={() => setShowModal(false)}
      closeHandler={() => setShowModal(false)}
      title={COPY.CASE_DISTRIBUTION_MODAL_TITLE}
      confirmButton={<Button onClick={handleConfirmButton}>{COPY.MODAL_CONFIRM_BUTTON}</Button>}
      cancelButton={<Button onClick={() => setShowModal(false)}>{COPY.MODAL_CANCEL_BUTTON}</Button>}
      className={styles.updatedModalStyling}
    >
      <p>{COPY.CASE_DISTRIBUTION_MODAL_DESCRIPTION}</p>
      {leverList()}
    </Modal>);
};

SaveModal.propTypes = {
  setShowModal: PropTypes.func.isRequired,
  handleConfirmButton: PropTypes.func.isRequired
};

export default SaveModal;
