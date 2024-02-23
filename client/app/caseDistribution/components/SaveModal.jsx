
import React from 'react';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import { useSelector } from 'react-redux';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import cx from 'classnames';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { findOption, findValueOption } from '../utils';
import { changedLevers } from '../reducers/levers/leversSelector';

export const SaveModal = (props) => {
  const { setShowModal, handleConfirmButton } = props;

  const theState = useSelector((state) => state);

  const combinationValue = (value, isToggleActive) => {
    const toggleString = isToggleActive ? 'Active' : 'Inactive';

    return `${toggleString} - ${value}`;
  };

  /**
   * If omit or infinite
   *  Return the text for the option
   *
   * If value
   *  Return the text, value, and unit for the option
   */
  const radioValue = (lever, value) => {
    if ([ACD_LEVERS.omit, ACD_LEVERS.infinite].includes(value)) {
      return findOption(lever, value).text;
    }

    const selectedOption = findValueOption(lever);

    return `${selectedOption.text} ${value} ${selectedOption.unit}`;
  };

  const changedLeverDisplayValue = (lever, value, isToggleActive) => {
    let displayValue = value;

    if (lever.data_type === ACD_LEVERS.data_types.radio) {
      displayValue = radioValue(lever, value);
    }

    if (lever.data_type === ACD_LEVERS.data_types.combination) {
      displayValue = combinationValue(value, isToggleActive);
    }

    return displayValue;
  };

  const backendValueDisplay = (lever) => {
    return <>{changedLeverDisplayValue(lever, lever.backendValue, lever.backendIsToggleActive)}</>;
  };

  const leverValueDisplay = (lever) => {
    return <strong>{changedLeverDisplayValue(lever, lever.value, lever.is_toggle_active)}</strong>;
  };

  const leverList = () => {
    const updatedLevers = changedLevers(theState);

    return (
      <div>
        <table id="case-distribution-control-modal-table">
          <tbody>
            <tr>
              <th className={cx('modal-table-header-styling', 'modal-table-left-styling')} scope="column">
                {COPY.CASE_DISTRIBUTION_LEVER_SAVE_BUTTON_DATA}
              </th>
              <th className={cx('modal-table-header-styling', 'modal-table-right-styling')} scope="column">
                {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_PREV_VALUE}
              </th>
              <th className={cx('modal-table-header-styling', 'modal-table-right-styling')} scope="column">
                {COPY.CASE_DISTRIBUTION_LEVER_SAVE_BUTTON_VALUE}
              </th>
            </tr>
          </tbody>
          <tbody>
            {updatedLevers.map((lever, index) => (
              <tr key={index} id={`case-distribution-control-modal-table-${index}`}>
                <React.Fragment>
                  <td
                    id={`${lever.item}-title-in-modal`}
                    className={cx('modal-table-styling', 'modal-table-left-styling')}
                  >
                    {lever.title}
                  </td>
                  <td
                    id={`${lever.item}-previous-value`}
                    className={cx('modal-table-styling', 'modal-table-right-styling')}
                  >
                    {backendValueDisplay(lever)}
                  </td>
                  <td
                    id={`${lever.item}-new-value`}
                    className={cx('modal-table-styling', 'modal-table-right-styling')}
                  >
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
      className="updated-modal-styling"
      title={COPY.CASE_DISTRIBUTION_MODAL_TITLE}
      confirmButton={<Button id="save-modal-confirm" onClick={handleConfirmButton}>
        {COPY.MODAL_CONFIRM_BUTTON}</Button>}

      cancelButton={<Button id="save-modal-cancel" onClick={() => setShowModal(false)}>
        {COPY.MODAL_CANCEL_BUTTON}</Button>}
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
