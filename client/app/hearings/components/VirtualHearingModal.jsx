import React from 'react';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import Modal from '../../components/Modal';
import TextField from '../../components/TextField';
import moment from 'moment';

const VirtualHearingModal = ({ virtualHearing, hearing, update }) => (
  <div>
    <Modal
      title="Change to Virtual Hearing"
      closeHandler={() => {}}
      confirmButton={
        <Button classNames={['usa-button-secondary']} onClick={() => {}}>
          Change and Send Email
        </Button>
      }
      cancelButton={
        <Button linkStyling onClick={() => {}}>Cancel</Button>
      }>
      <p>
        Calendar invites will be emailed to the Veteran, POA/Representative, and VLJ.
      </p>
      <div>
        <strong>{'Date:'}&nbsp;</strong>{moment(hearing.scheduledFor).format('MM/DD/YYYY')}<br />
        <strong>{'Time:'}&nbsp;</strong>{moment(hearing.scheduledTimeString, "hh:mm").format('LT')}
      </div>
      <TextField
        strongLabel
        name="vet-email"
        label="Veteran Email"
        onChange={(veteranEmail) => update({ veteranEmail })} />
      <TextField
        strongLabel
        name="rep-email"
        label="POA/Representative Email"
        onChange={(representativeEmail) => update({ representativeEmail })} />

      <p>
        Changes to the Veteran and POA/Representative emails will be used to send calendar invites and reminders <strong>for this hearing only</strong>.
      </p>
    </Modal>
  </div>
);


VirtualHearingModal.propTypes = {
  virtualHearing: PropTypes.shape({
    veteranEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  }),
  hearing: PropTypes.shape({
    scheduledFor: PropTypes.string,
    scheduledTimeString: PropTypes.string
  }).isRequired,
  update: PropTypes.func
};

export default VirtualHearingModal;
