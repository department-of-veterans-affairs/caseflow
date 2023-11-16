import React, { useState } from 'react';
import PropTypes, { string } from 'prop-types';
import Modal from '../../../../components/Modal';
import Checkbox from '../../../../components/Checkbox';
import { css } from 'glamor';

const CheckboxModal = (props) => {

  const [toggledCheckBoxes, setToggledCheckboxes] = useState([]);

  const handleToggleCheckbox = (checkboxId) => {
    const index = toggledCheckBoxes.indexOf(checkboxId);
    const checkboxes = [...toggledCheckBoxes];

    // remove it if checkboxes contains it, append it if it doesn't
    if (index === -1) {
      checkboxes.push(checkboxId);
    } else {
      checkboxes.splice(index, 1);
    }
    setToggledCheckboxes(checkboxes);
  };

  const handleClear = () => {
    setToggledCheckboxes([]);
  };

  const checkboxSizeStyling = css({
    transform: 'scale(1.3)',
    translate: '10%',
  });

  const testTyle = {backgroundColor: 'red'}

  return (
    <Modal
      title="Add autotext"
      customStyles={{ style: { scrollbarWidth: 'none', width: '40%' } }}
      closeHandler={props.closeHandler}
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: props.closeHandler,
          disabled: false,
        },
        {
          id: '#add-autotext-button',
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Add',
          onClick: () => props.handleAdd(toggledCheckBoxes),
          disabled: false
        },
        {
          id: '#Delete-Comment-button',
          classNames: ['usa-button', 'usa-button-secondary', 'usa-grid-full', testTyle],
          name: 'Clear all',
          onClick: () => handleClear(),
          disabled: false
        }
      ]}>
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        overflowY: 'scroll',
        maxHeight: '500px',
        paddingLeft: '5%',
        marginLeft: '2%',
        paddingRight: '5%',
        width: '100%',
        overflowX: 'hidden' }}>
        {props.checkboxData.map((checkboxText, index) => (
          <Checkbox
            name={checkboxText}
            styling={checkboxSizeStyling}
            onChange={() => handleToggleCheckbox(index)}
            value={toggledCheckBoxes.indexOf(index) > -1}
          />))
        }
      </div>
    </Modal>
  );
};

CheckboxModal.propTypes = {
  // the method which the modal executes when the ok button is pressed.
  handleAdd: PropTypes.func,

  // responsible for closing the modal. Occurs on both the close button and the X in the top right.
  closeHandler: PropTypes.func,

  // the values that will be used as names for the checkboxes.
  checkboxData: PropTypes.arrayOf(string)

};

export default CheckboxModal;
