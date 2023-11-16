import React, { useState } from 'react';
import Modal from '../../../../components/Modal';
import Checkbox from '../../../../components/Checkbox';
import { style, css, backdrop } from 'glamor';

const CheckboxModal = (props) => {

  const [toggledCheckBoxes, setToggledCheckboxes] = useState([]);

  const handleToggleCheckbox = (checkboxId) => {
    const index = toggledCheckBoxes.indexOf(checkboxId);
    const checkboxes = [...toggledCheckBoxes];

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

  const hearingPreppedStyling = css({
    transform: 'scale(1.3)',
    translate: '17%',
    // overflowX: 'scroll'
  });

  return (
    <Modal
      title="Add autotext"
      customStyles={{ style: { scrollbarWidth: 'none', width: '40%' } }}
      closeHandler={props.closeHandler}
      confirmHandler={(test) => props.addHandler(test)}
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: props.closeHandler,
          disabled: false
        },
        {
          id: '#add-autotext-button',
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Add',
          onClick: () => props.debug(toggledCheckBoxes),
          disabled: false
        },
        {
          id: '#Delete-Comment-button',
          classNames: ['usa-button', 'usa-button-secondary'],
          name: 'Clear all',
          onClick: () => handleClear(),
          disabled: false
        }
      ]}>
      <div style={{ display: 'flex',
        flexDirection: 'column',
        overflowY: 'scroll',
        maxHeight: '500px',
        paddingLeft: 0,
        marginLeft: '2%',
        width: '100%',
        overflowX: 'hidden' }}>
        {props.data.map((data, i) => <Checkbox name={data}
          styling={hearingPreppedStyling}
          onChange={() => handleToggleCheckbox(i)}
          value={toggledCheckBoxes.indexOf(i) > -1}
        />)
        }
      </div>
    </Modal>
  );
};

export default CheckboxModal;
