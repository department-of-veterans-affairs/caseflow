import React from 'react';
import Modal from '../../../../components/Modal';
import Checkbox from '../../../../components/Checkbox';
import { style, css } from 'glamor';

const CheckboxModal = (props) => {

  const hearingPreppedStyling = css({
    margin: '4rem 4rem 0 1.75rem'
  });

  return (
    <Modal
      title="Add autotext"
      customStyles={{ style: { scrollbarWidth: 'none' } }}

      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: () => console.log('Cancel'),
          disabled: false
        },
        {
          id: '#Delete-Comment-button',
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Add',
          onClick: () => console.log('confirm?'),
          disabled: false
        },
        {
          id: '#Delete-Comment-button',
          classNames: ['usa-button', 'usa-button-secondary'],
          name: 'Clear all',
          onClick: () => console.log('confirm?'),
          disabled: false
        }
      ]}>
      <div style={{ display: 'flex', flexDirection: 'column', overflowY: 'scroll', maxHeight: '500px' }}>
        {props.data.map((data) => <Checkbox name={data} />)
        }
      </div>
    </Modal>
  );
};

export default CheckboxModal;
