import React from 'react';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import Modal from '../../components/Modal';
import TextField from '../../components/TextField';
import moment from 'moment';
import COPY from '../../../COPY.json';

const formatTimeString = (hearing) => {
  let timeString = `${moment(hearing.centralOfficeTimeString, 'hh:mm').format('h:mm a')} ET`;

  if (hearing.regionalOfficeTimezone !== 'America/New_York') {
    timeString += ` / ${moment(hearing.scheduledTimeString, 'hh:mm').format('h:mm a')} `;
    timeString += moment().tz(hearing.regionalOfficeTimezone).
      format('z');
  }

  return timeString;
};

const VirtualHearingModal = ({ virtualHearing, hearing, update, submit, reset }) => (
  <div>
    <Modal
      title="Change to Virtual Hearing"
      closeHandler={reset}
      confirmButton={
        <Button classNames={['usa-button-secondary']}
          onClick={submit} >
          Change and Send Email
        </Button>
      }
      cancelButton={
        <Button linkStyling onClick={reset}>Cancel</Button>
      }>
      <p>
        {COPY.VIRTUAL_HEARING_MODAL_INTRO}
      </p>
      <div>
        <strong>{'Date:'}&nbsp;</strong>{moment(hearing.scheduledFor).format('MM/DD/YYYY')}<br />
        <strong>{'Time:'}&nbsp;</strong>{formatTimeString(hearing)}
      </div>
      <TextField
        strongLabel
        value={virtualHearing.veteranEmail}
        name="vet-email"
        label="Veteran Email"
        onChange={(veteranEmail) => update({ veteranEmail })} />
      <TextField
        strongLabel
        value={virtualHearing.representativeEmail}
        name="rep-email"
        label="POA/Representative Email"
        onChange={(representativeEmail) => update({ representativeEmail })} />

      <p dangerouslySetInnerHTML={{ __html: COPY.VIRTUAL_HEARING_MODAL_CONFIRMATION }} />
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
    scheduledTimeString: PropTypes.string,
    regionalOfficeTimezone: PropTypes.string,
    centralOfficeTimeString: PropTypes.string
  }).isRequired,
  update: PropTypes.func,
  submit: PropTypes.func,
  reset: PropTypes.func
};

export default VirtualHearingModal;
