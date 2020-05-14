import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import _ from 'lodash';
import moment from 'moment-timezone';

import { getAppellantTitleForHearing } from '../utils';
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

const ReadOnlyEmails = (
  { hearing, virtualHearing, appellantEmailEdited, representativeEmailEdited, showAllEmails = false }
) => {
  const appellantTitle = getAppellantTitleForHearing(hearing);

  return (
    <React.Fragment>
      {(appellantEmailEdited || showAllEmails) && (
        <p>
          <strong>{appellantTitle} Email</strong>
          <br />
          {virtualHearing.appellantEmail}
        </p>
      )}
      {(representativeEmailEdited || showAllEmails) && (
        <p>
          <strong>Representative Email</strong>
          <br />
          {virtualHearing.representativeEmail}
        </p>
      )}
    </React.Fragment>
  );
};

ReadOnlyEmails.propTypes = {
  hearing: PropTypes.shape({
    appellantIsNotVeteran: PropTypes.bool
  }),
  virtualHearing: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  }),
  appellantEmailEdited: PropTypes.bool,
  representativeEmailEdited: PropTypes.bool,
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

const ChangeFromVirtual = (props) => {
  const hearing = { props };

  return (
    <React.Fragment>
      <DateTime {...props} />
      {hearing.location && (
        <div>
          <strong>Location:&nbsp;</strong>
          {hearing.location.name}
        </div>
      )}
      <ReadOnlyEmails {...props} showAllEmails />
    </React.Fragment>
  );
};

ChangeFromVirtual.propTypes = {
  hearing: PropTypes.shape({
    location: PropTypes.shape({
      name: PropTypes.string
    })
  })
};

const ChangeToVirtual = (props) => {
  const {
    hearing, readOnly, representativeEmailError, update, appellantEmailError, virtualHearing
  } = props;
  const appellantTitle = getAppellantTitleForHearing(hearing);

  // Prefill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    if (_.isUndefined(virtualHearing.appellantEmail)) {
      update({ appellantEmail: hearing.appellantEmailAddress });
    }

    if (_.isUndefined(virtualHearing.representativeEmail)) {
      update({ representativeEmail: hearing.representativeEmailAddress });
    }
  }, []);

  return (
    <React.Fragment>
      <DateTime {...props} />
      <TextField
        strongLabel
        value={virtualHearing.appellantEmail}
        name="appellant-email"
        label={`${appellantTitle} Email`}
        errorMessage={appellantEmailError}
        readOnly={readOnly}
        onChange={(appellantEmail) => update({ appellantEmail })}
      />
      <TextField
        strongLabel
        value={virtualHearing.representativeEmail}
        name="representative-email"
        label="POA/Representative Email"
        errorMessage={representativeEmailError}
        readOnly={readOnly}
        onChange={(representativeEmail) => update({ representativeEmail })}
      />
      <p
        dangerouslySetInnerHTML={
          { __html: sprintf(COPY.VIRTUAL_HEARING_MODAL_CONFIRMATION, { appellantTitle }) }
        }
      />
    </React.Fragment>
  );
};

ChangeToVirtual.propTypes = {
  hearing: PropTypes.shape({
    appellantEmailAddress: PropTypes.string,
    appellantIsNotVeteran: PropTypes.bool,
    representativeEmailAddress: PropTypes.string
  }),
  readOnly: PropTypes.bool,
  representativeEmailError: PropTypes.string,
  update: PropTypes.func,
  appellantEmailError: PropTypes.string,
  virtualHearing: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string
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
  const [appellantEmailError, setAppellantEmailError] = useState(null);
  const [representativeEmailError, setRepresentativeEmailError] = useState(null);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const typeSettings = TYPES[type];
  const appellantTitle = getAppellantTitleForHearing(hearing);

  const validateForm = () => {
    if (_.isEmpty(virtualHearing.appellantEmail)) {
      setAppellantEmailError(INVALID_EMAIL_FORMAT);

      return false;
    }

    return true;
  };

  const onSubmit = () => {
    if (!validateForm()) {
      return;
    }

    setLoading(true);

    return submit()
      ?.then(() => setSuccess(true))
      ?.then(closeModal)
      ?.catch((error) => {
        // Details.jsx re-throws email invalid error that we catch here.
        const msg = error.response.body.errors[0].message;

        setRepresentativeEmailError(msg.indexOf('Representative') === -1 ? null : INVALID_EMAIL_FORMAT);
        setAppellantEmailError(msg.indexOf('Veteran') === -1 ? null : INVALID_EMAIL_FORMAT);
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
        title={sprintf(typeSettings.title, { appellantTitle })}
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
        <p
          dangerouslySetInnerHTML={
            { __html: sprintf(typeSettings.intro, { appellantTitle }) }
          }
        />

        <typeSettings.element
          {...props}
          readOnly={loading || success}
          appellantEmailError={appellantEmailError}
          representativeEmailError={representativeEmailError}
        />
      </Modal>
    </div>
  );
};

VirtualHearingModal.propTypes = {
  virtualHearing: PropTypes.shape({
    appellantEmail: PropTypes.string,
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
    appellantEmailAddress: PropTypes.string,
    appellantIsNotVeteran: PropTypes.bool,
    representativeEmailAddress: PropTypes.string
  }).isRequired,
  type: PropTypes.oneOf([
    'change_to_virtual',
    'change_from_virtual',
    'change_email',
    'change_hearing_time'
  ]).isRequired,
  timeWasEdited: PropTypes.bool,
  representativeEmailEdited: PropTypes.bool,
  appellantEmailEdited: PropTypes.bool,
  update: PropTypes.func,
  submit: PropTypes.func,
  reset: PropTypes.func,
  closeModal: PropTypes.func
};

export default VirtualHearingModal;
