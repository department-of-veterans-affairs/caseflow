import PropTypes from 'prop-types';
import React, { useState } from 'react';
import _ from 'lodash';
import moment from 'moment-timezone';

import Button from '../../components/Button';
import COPY from '../../../COPY';
import Modal from '../../components/Modal';
import TextField from '../../components/TextField';

const getCentralOfficeTime = (hearing) => {
  const newTime = `${moment(hearing.scheduledFor).format('YYYY-MM-DD')}T${hearing.scheduledTimeString}`;

  return moment.
    tz(newTime, hearing.regionalOfficeTimezone).
    tz('America/New_York').
    format('hh:mm');
};

const formatTimeString = (hearing, timeWasEdited) => {
  if (hearing.regionalOfficeTimezone === 'America/New_York') {
    return `${moment(hearing.scheduledTimeString, 'hh:mm').format('h:mm a')} ET`;
  }

  const centralOfficeTime = timeWasEdited ? getCentralOfficeTime(hearing) : hearing.centralOfficeTimeString;

  let timeString = `${moment(centralOfficeTime, 'hh:mm').format('h:mm a')} ET`;

  timeString += ` / ${moment(hearing.scheduledTimeString, 'hh:mm').format('h:mm a')} `;
  timeString += moment().
    tz(hearing.regionalOfficeTimezone).
    format('z');

  return timeString;
};

const DateTime = ({ hearing, timeWasEdited }) => (
  <div>
    <strong>Date:&nbsp;</strong>
    {moment(hearing.scheduledFor).format('MM/DD/YYYY')}
    <br />
    <strong>Time:&nbsp;</strong>
    {formatTimeString(hearing, timeWasEdited)}
  </div>
);

DateTime.propTypes = {
  hearing: PropTypes.shape({
    scheduledFor: PropTypes.string
  }),
  timeWasEdited: PropTypes.bool
};

const ReadOnlyEmails = ({ virtualHearing, repEmailEdited, vetEmailEdited, showAllEmails = false }) => (
  <React.Fragment>
    {(vetEmailEdited || showAllEmails) && (
      <p>
        <strong>Veteran Email</strong>
        <br />
        {virtualHearing.veteranEmail}
      </p>
    )}
    {(repEmailEdited || showAllEmails) && (
      <p>
        <strong>Representative Email</strong>
        <br />
        {virtualHearing.representativeEmail}
      </p>
    )}
  </React.Fragment>
);

ReadOnlyEmails.propTypes = {
  virtualHearing: PropTypes.shape({
    veteranEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  }),
  vetEmailEdited: PropTypes.bool,
  repEmailEdited: PropTypes.bool,
  showAllEmails: PropTypes.bool
};

const ChangeHearingTime = (props) => (
  <React.Fragment>
    <DateTime {...props} />
    <ReadOnlyEmails {...props} showAllEmails />
  </React.Fragment>
);

const ChangeEmail = (props) => (
  <React.Fragment>
    <ReadOnlyEmails {...props} />
  </React.Fragment>
);

const ChangeFromVirtual = ({ hearing, ...props }) => (
  <React.Fragment>
    <DateTime {...props} hearing={hearing} />
    {hearing.location && (
      <div>
        <strong>Location:&nbsp;</strong>
        {hearing.location.name}
      </div>
    )}
    <ReadOnlyEmails {...props} showAllEmails />
  </React.Fragment>
);

ChangeFromVirtual.propTypes = {
  hearing: PropTypes.shape({
    location: PropTypes.shape({
      name: PropTypes.string
    })
  })
};

const ChangeToVirtual = (props) => {
  const { hearing, readOnly, repEmailError, update, vetEmailError, virtualHearing } = props;

  return (
    <React.Fragment>
      <DateTime {...props} />
      <TextField
        strongLabel
        value={
          _.isUndefined(virtualHearing.veteranEmail)
            ? hearing.veteranEmailAddress
            : virtualHearing.veteranEmail
        }
        name="vet-email"
        label="Veteran Email"
        errorMessage={vetEmailError}
        readOnly={readOnly}
        onChange={(veteranEmail) => update({ veteranEmail })}
      />
      <TextField
        strongLabel
        value={
          _.isUndefined(virtualHearing.representativeEmail)
            ? hearing.representativeEmailAddress
            : virtualHearing.representativeEmail
        }
        name="rep-email"
        label="POA/Representative Email"
        errorMessage={repEmailError}
        readOnly={readOnly}
        onChange={(representativeEmail) => update({ representativeEmail })}
      />
      <p dangerouslySetInnerHTML={{ __html: COPY.VIRTUAL_HEARING_MODAL_CONFIRMATION }} />
    </React.Fragment>
  );
};

ChangeToVirtual.propTypes = {
  hearing: PropTypes.shape({
    representativeEmailAddress: PropTypes.string,
    veteranEmailAddress: PropTypes.string
  }),
  readOnly: PropTypes.bool,
  repEmailError: PropTypes.string,
  update: PropTypes.func,
  vetEmailError: PropTypes.string,
  virtualHearing: PropTypes.shape({
    representativeEmail: PropTypes.string,
    veteranEmail: PropTypes.string
  })
};

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
    intro: COPY.VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_INTRO,
    button: COPY.VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON,
    element: ChangeEmail
  }
};

const VirtualHearingModal = (props) => {
  const { closeModal, hearing, virtualHearing, reset, submit, type } = props;
  const [vetEmailError, setVetEmailError] = useState(null);
  const [repEmailError, setRepEmailError] = useState(null);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const typeSettings = TYPES[type];

  const validateForm = () => {
    if (_.isEmpty(virtualHearing.veteranEmail)) {
      setVetEmailError(INVALID_EMAIL_FORMAT);

      return false;
    }

    return true;
  };

  const onSubmit = () => {
    if (!validateForm()) {
      return;
    }

    setLoading(true);

    submit()
      ?.then(() => setSuccess(true))
      ?.then(closeModal)
      ?.catch((error) => {
        // Details.jsx re-throws email invalid error that we catch here.
        const msg = error.response.body.errors[0].message;

        setRepEmailError(msg.indexOf('Representative') === -1 ? null : INVALID_EMAIL_FORMAT);
        setVetEmailError(msg.indexOf('Veteran') === -1 ? null : INVALID_EMAIL_FORMAT);
      })
      ?.finally(() => setLoading(false));
  };

  const onReset = () => {
    reset();
    closeModal();
  };

  return (
    <div>
      <Modal
        title={typeSettings.title}
        closeHandler={onReset}
        confirmButton={
          <Button
            name="submit-virtual-hearing"
            classNames={['usa-button-secondary']}
            disabled={success}
            loading={loading}
            onClick={onSubmit}
          >
            {typeSettings.button || COPY.VIRTUAL_HEARING_CHANGE_HEARING_BUTTON}
          </Button>
        }
        cancelButton={
          <Button
            name="cancel-virtual-hearing"
            linkStyling
            disabled={loading || success}
            onClick={onReset}
          >
            Cancel
          </Button>
        }
      >
        <p dangerouslySetInnerHTML={{ __html: typeSettings.intro }} />

        <typeSettings.element
          {...props}
          readOnly={loading || success}
          vetEmailError={vetEmailError}
          repEmailError={repEmailError}
        />
      </Modal>
    </div>
  );
}

VirtualHearingModal.propTypes = {
  virtualHearing: PropTypes.shape({
    veteranEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  }).isRequired,
  hearing: PropTypes.shape({
    scheduledFor: PropTypes.string,
    scheduledTimeString: PropTypes.string,
    regionalOfficeTimezone: PropTypes.string,
    centralOfficeTimeString: PropTypes.string,
    location: PropTypes.shape({
      name: PropTypes.string
    }),
    veteranEmailAddress: PropTypes.string,
    representativeEmailAddress: PropTypes.string
  }).isRequired,
  type: PropTypes.oneOf([
    'change_to_virtual',
    'change_from_virtual',
    'change_email',
    'change_hearing_time'
  ]).isRequired,
  timeWasEdited: PropTypes.bool,
  repEmailEdited: PropTypes.bool,
  vetEmailEdited: PropTypes.bool,
  update: PropTypes.func,
  submit: PropTypes.func,
  reset: PropTypes.func,
  closeModal: PropTypes.func
};

export default VirtualHearingModal;
