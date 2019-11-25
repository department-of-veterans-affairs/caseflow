import React from 'react';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import Modal from '../../components/Modal';
import TextField from '../../components/TextField';
import moment from 'moment';
import COPY from '../../../COPY.json';
import _ from 'lodash';
import { deepDiff } from '../utils';

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

const DateTime = ({ hearing, timeWasEdited }) => (
  <div>
    <strong>{'Date:'}&nbsp;</strong>{moment(hearing.scheduledFor).format('MM/DD/YYYY')}<br />
    <strong>{'Time:'}&nbsp;</strong>{formatTimeString(hearing, timeWasEdited)}
  </div>
);

const ReadOnlyEmails = ({
  virtualHearing, repEmailChanged, vetEmailChanged, showOnlyChanged = false
}) => (
  <React.Fragment>
    {(vetEmailChanged && showOnlyChanged) && <div>
      <div><strong>Veteran Email</strong></div>
      <p>{virtualHearing.veteranEmail}</p>
    </div>}
    {(repEmailChanged && showOnlyChanged) && <div>
      <div><strong>Representative Email</strong></div>
      <p>{virtualHearing.representativeEmail}</p>
    </div>}
  </React.Fragment>
);

const Emails = ({ virtualHearing, update, vetEmailError, repEmailError }) => (
  <React.Fragment>
    <TextField
      strongLabel
      value={virtualHearing.veteranEmail}
      name="vet-email"
      label="Veteran Email"
      errorMessage={vetEmailError}
      onChange={(veteranEmail) => update({ veteranEmail })} />
    <TextField
      strongLabel
      value={virtualHearing.representativeEmail}
      name="rep-email"
      label="POA/Representative Email"
      errorMessage={repEmailError}
      onChange={(representativeEmail) => update({ representativeEmail })} />
  </React.Fragment>
);

const ChangeHearingTime = (props) => (
  <React.Fragment>
    <DateTime {...props} />
    <ReadOnlyEmails {...props} />
  </React.Fragment>
);

const ChangeEmail = (props) => (
  <React.Fragment>
    <ReadOnlyEmails {...props} showOnlyChanged />
  </React.Fragment>
);

const ChangeFromVirtual = (props) => (
  <React.Fragment>
    <DateTime {...props} />
    <strong>{'Location:'}&nbsp;</strong>{props.hearing.location.name}
    <ReadOnlyEmails {...props} />
  </React.Fragment>
);

const ChangeToVirtual = (props) => (
  <React.Fragment>
    <DateTime {...props} />
    <Emails {...props} />
    <p dangerouslySetInnerHTML={{ __html: COPY.VIRTUAL_HEARING_MODAL_CONFIRMATION }} />
  </React.Fragment>
);

const INVALID_EMAIL_FORMAT = 'Please enter a valid email address';

const TYPES = {
  change_to_virtual: {
    title: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_TITLE,
    intro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_INTRO,
    element: ChangeToVirtual
  },
  change_from_virtual: {
    title: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIDEO_TITLE,
    intro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIDEO_INTRO,
    element: ChangeFromVirtual
  },
  change_hearing_time: {
    title: COPY.VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_TITLE,
    intro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_INTRO,
    element: ChangeHearingTime
  },
  change_email: {
    title: COPY.VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_TITLE,
    intro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_INTRO,
    button: COPY.VIRTUAL_HEARING_UPDATE_EMAIL_MODAL_INTRO,
    element: ChangeEmail
  }
};

class VirtualHearingModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      vetEmailError: null,
      repEmailError: null
    };
  }

  getChangedEmails = () => {
    const { hearing: initialHearing, virtualHearing } = this.props;

    const changes = deepDiff(initialHearing.virtualHearing, virtualHearing);

    return {
      repEmailChanged: !_.isUndefined(changes.representativeEmail),
      vetEmailChanged: !_.isUndefined(changes.veteranEmail)
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
    const { type, reset } = this.props;
    const { vetEmailError, repEmailError } = this.state;

    const typeSettings = TYPES[type];

    return <div>
      <Modal
        title={typeSettings.title}
        closeHandler={reset}
        confirmButton={
          <Button classNames={['usa-button-secondary']}
            onClick={this.onSubmit}>
            {typeSettings.button || COPY.VIRTUAL_HEARING_CHANGE_HEARING_BUTTON}
          </Button>
        }
        cancelButton={
          <Button linkStyling onClick={reset}>Cancel</Button>
        }>
        <p>
          {typeSettings.intro}
        </p>
        <typeSettings.element
          {...this.props}
          {...this.getChangedEmails()}
          vetEmailError={vetEmailError}
          repEmailError={repEmailError} />
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
  type: PropTypes.oneOf([
    'change_to_virtual', 'change_from_virtual',
    'change_email', 'change_hearing_time'
  ]),
  timeWasEdited: PropTypes.bool,
  update: PropTypes.func,
  submit: PropTypes.func,
  reset: PropTypes.func,
  closeModal: PropTypes.func,
  modalTitle: PropTypes.string,
  modalIntro: PropTypes.string,
  modalButton: PropTypes.string
};

export default VirtualHearingModal;
