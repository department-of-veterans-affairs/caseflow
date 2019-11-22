import React from 'react';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import Modal from '../../components/Modal';
import TextField from '../../components/TextField';
import moment from 'moment';
import COPY from '../../../COPY.json';
import _ from 'lodash';

const getCentralOfficeTime = (hearing) => {
  const newTime = `${moment(hearing.scheduledFor).format('YYYY-MM-DD')}T${hearing.scheduledTimeString}`;

  return moment.tz(newTime, hearing.regionalOfficeTimezone).tz('America/New_York').
    format('hh:mm');
};

const formatTimeString = (hearing, timeWasEdited) => {
  if (hearing.regionalOfficeTimezone === 'America/New_York') {
    return `${moment(hearing.scheduledTimeString, 'hh:mm').format('h:mm a')} ET`;
  }

  const centralOfficeTime = timeWasEdited ? getCentralOfficeTime(hearing) : hearing.centralOfficeTimeString;

  let timeString = `${moment(centralOfficeTime, 'hh:mm').format('h:mm a')} ET`;

  timeString += ` / ${moment(hearing.scheduledTimeString, 'hh:mm').format('h:mm a')} `;
  timeString += moment().tz(hearing.regionalOfficeTimezone).
    format('z');

  return timeString;
};
// alsia look in COPY
const INVALID_EMAIL_FORMAT = 'Please enter a valid email address';

class VirtualHearingModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      vetEmailError: null,
      repEmailError: null
    };
  }
  validateForm = () => {
    let { virtualHearing } = this.props;
    let isValid = true;

    if (_.isEmpty(virtualHearing.veteranEmail)) {
      this.setState({ vetEmailError: INVALID_EMAIL_FORMAT });
      isValid = false;
    }
    if (_.isEmpty(virtualHearing.representativeEmail)) {
      this.setState({ repEmailError: INVALID_EMAIL_FORMAT });
      isValid = false;
    }

    return isValid;
  }
  onSubmit = () => {
    let { closeModal, submit } = this.props;

    if (this.validateForm()) {
      submit().then(closeModal).
        catch((error) => {
        // Details.jsx re-throws email invalid error that we catch here.
          const msg = error.response.body.errors[0].message;

          this.setState({
            repEmailError: msg.indexOf('Representative') === -1 ? null : INVALID_EMAIL_FORMAT,
            vetEmailError: msg.indexOf('Veteran') === -1 ? null : INVALID_EMAIL_FORMAT
          });
        });
    }
  }

  render () {
    let { virtualHearing, hearing, timeWasEdited, update, reset } = this.props;

    return <div>
      <Modal
        title="Change to Virtual Hearing"
        closeHandler={reset}
        confirmButton={
          <Button classNames={['usa-button-secondary']}
            onClick={this.onSubmit}>
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
          <strong>{'Time:'}&nbsp;</strong>{formatTimeString(hearing, timeWasEdited)}
        </div>
        <TextField
          strongLabel
          value={virtualHearing.veteranEmail}
          name="vet-email"
          label="Veteran Email"
          errorMessage={this.state.vetEmailError}
          onChange={(veteranEmail) => update({ veteranEmail })} />
        <TextField
          strongLabel
          value={virtualHearing.representativeEmail}
          name="rep-email"
          label="POA/Representative Email"
          errorMessage={this.state.repEmailError}
          onChange={(representativeEmail) => update({ representativeEmail })} />

        <p dangerouslySetInnerHTML={{ __html: COPY.VIRTUAL_HEARING_MODAL_CONFIRMATION }} />
      </Modal>
    </div>;
  }
}

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
  timeWasEdited: PropTypes.bool,
  update: PropTypes.func,
  submit: PropTypes.func,
  reset: PropTypes.func,
  closeModal: PropTypes.func
};

export default VirtualHearingModal;
