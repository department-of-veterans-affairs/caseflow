import React from 'react';
import Modal from '../../../../components/Modal';
import Checkbox from '../../../../components/Checkbox';
import { style, css, backdrop } from 'glamor';

const CheckboxModal = (props) => {

  const hearingPreppedStyling = css({
    transform: 'scale(1.3)',
    translate: '15%',
    // overflowX: 'scroll'
  });

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
      <div style={{ display: 'flex',
        flexDirection: 'column',
        overflowY: 'scroll',
        maxHeight: '500px',
        paddingLeft: 0,
        marginLeft: '2%',
        width: '100%',
        overflowX: 'hidden' }}>
        {props.data.map((data) => <Checkbox name={data}
          styling={hearingPreppedStyling}
        // inputProps={{style:{hearingPreppedStyling}}}
        />)
        }
      </div>
    </Modal>
  );
};

export default CheckboxModal;
