import { sprintf } from 'sprintf-js';
import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import _ from 'lodash';
import moment from 'moment-timezone';

import { getAppellantTitle, zoneName } from '../utils';
import Button from '../../components/Button';
import COPY from '../../../COPY';
import Modal from '../../components/Modal';
import TextField from '../../components/TextField';
import { HEARING_CONVERSION_TYPES } from '../constants';
import { ReadOnly } from './details/ReadOnly';
import { virtualHearingModalStyles } from './details/style';

const getCentralOfficeTime = (hearing) => {
  const newTime = `${moment(hearing.scheduledFor).format('YYYY-MM-DD')}T${hearing.scheduledTimeString}`;

  return moment.
    tz(newTime, hearing.regionalOfficeTimezone).
    tz('America/New_York').
    format('HH:mm');
};

const formatTimeString = (hearing, timeWasEdited) => {
  // Format the time string with Central Office time for formerly Central hearings
  if (
    hearing.readableRequestType === 'Central' ||
    hearing.regionalOfficeTimezone === 'America/New_York'
  ) {
    return zoneName(hearing.scheduledTimeString);
  }

  const centralOfficeTime = timeWasEdited ? getCentralOfficeTime(hearing) : hearing.centralOfficeTimeString;

  let timeString = `${moment(centralOfficeTime, 'hh:mm').format('h:mm a')} ET`;

  timeString += ` / ${moment(hearing.scheduledTimeString, 'hh:mm').format('h:mm a')} `;
  timeString += moment().
    tz(hearing.regionalOfficeTimezone).
    format('z');

  return timeString;
};

export const DateTime = ({ hearing, timeWasEdited }) => (
  <div>
    <strong>Hearing Date:&nbsp;</strong>
    {moment(hearing.scheduledFor).format('MM/DD/YYYY')}
    <br />
    <strong>Hearing Time:&nbsp;</strong>
    {formatTimeString(hearing, timeWasEdited)}
    {hearing.readableRequestType === 'Central' && <div className="cf-help-divider" />}
  </div>
);

DateTime.propTypes = {
  hearing: PropTypes.shape({
    readableRequestType: PropTypes.string,
    scheduledFor: PropTypes.string,
  }),
  timeWasEdited: PropTypes.bool
};

export const ReadOnlyEmails = ({
  hearing,
  virtualHearing,
  appellantEmailEdited,
  representativeEmailEdited,
  representativeTzEdited,
  appellantTzEdited,
  showAllEmails = false,
}) => {
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);

  // Check for appellant edits
  const appellantEdited = appellantTzEdited || appellantEmailEdited ?
    representativeEmailEdited || representativeTzEdited :
    false;

  // Check for representative edits
  const repEdited = representativeEmailEdited || representativeTzEdited ?
    appellantTzEdited || appellantEmailEdited :
    false;

  // Determine whether ti display a divider
  const showDivider = virtualHearing.representativeEmail && (repEdited || appellantEdited || showAllEmails);
  const scheduledTimeString = moment(hearing.scheduledFor).tz('America/New_York').
    format('hh:mm');

  return (
    <div {...virtualHearingModalStyles}>
      {(appellantTzEdited || appellantEmailEdited || showAllEmails) && (
        <React.Fragment>
          <ReadOnly
            spacing={15}
            label={`${appellantTitle} Hearing Time`}
            text={zoneName(scheduledTimeString, virtualHearing.appellantTz)}
          />
          <ReadOnly
            spacing={15}
            label={`${appellantTitle} Email`}
            text={virtualHearing.appellantEmail}
          />
        </React.Fragment>
      )}
      {showDivider && <div className="cf-help-divider" />}
      {(virtualHearing.representativeEmail &&
       (representativeTzEdited || representativeEmailEdited || showAllEmails)) && (
        <React.Fragment>
          <ReadOnly
            spacing={15}
            label="POA/Representative Hearing Time"
            text={zoneName(scheduledTimeString, virtualHearing.representativeTz)}
          />
          <ReadOnly
            spacing={15}
            label="POA/Representative Email"
            text={virtualHearing.representativeEmail}
          />
        </React.Fragment>
      )}
    </div>
  );
};

ReadOnlyEmails.propTypes = {
  hearing: PropTypes.shape({
    appellantIsNotVeteran: PropTypes.bool,
    readableRequestType: PropTypes.string,
    scheduledFor: PropTypes.string
  }),
  virtualHearing: PropTypes.shape({
    representativeTz: PropTypes.string,
    appellantTz: PropTypes.string,
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
  }),
  appellantEmailEdited: PropTypes.bool,
  representativeEmailEdited: PropTypes.bool,
  representativeTzEdited: PropTypes.bool,
  appellantTzEdited: PropTypes.bool,
  showAllEmails: PropTypes.bool,
};

export const ChangeHearingTime = (props) => (
  <React.Fragment>
    <DateTime {...props} />
    <ReadOnlyEmails {...props} showAllEmails />
  </React.Fragment>
);

export const ChangeEmailOrTimezone = (props) => (
  <React.Fragment>
    <ReadOnlyEmails {...props} />
  </React.Fragment>
);

export const ChangeFromVirtual = (props) => {
  const { hearing } = props;

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

export const ChangeToVirtual = (props) => {
  const {
    hearing, readOnly, representativeEmailError, update, appellantEmailError, virtualHearing
  } = props;
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);

  // Prefill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    // Determine which email to use
    const appellantEmail = hearing.appellantIsNotVeteran ? hearing.appellantEmailAddress : hearing.veteranEmailAddress;

    // Set the emails if not already set
    update('virtualHearing', {
      [!virtualHearing?.appellantEmail && 'appellantEmail']: appellantEmail,
      [!virtualHearing?.representativeEmail && 'representativeEmail']: hearing.representativeEmailAddress
    });
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
        onChange={(appellantEmail) => update('virtualHearing', { appellantEmail })}
      />
      <TextField
        strongLabel
        value={virtualHearing.representativeEmail}
        name="representative-email"
        label="POA/Representative Email"
        errorMessage={representativeEmailError}
        readOnly={readOnly}
        onChange={(representativeEmail) => update('virtualHearing', { representativeEmail })}
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
    representativeEmailAddress: PropTypes.string,
    veteranEmailAddress: PropTypes.string
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

export const TYPES = {
  change_to_virtual: {
    title: () => COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_TITLE,
    intro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_INTRO,
    element: ChangeToVirtual
  },
  change_from_virtual: {
    title: () => COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIDEO_TITLE,
    intro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIDEO_INTRO,
    element: ChangeFromVirtual
  },
  change_hearing_time: {
    title: () => COPY.VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_TITLE,
    intro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_INTRO,
    button: COPY.VIRTUAL_HEARING_MODAL_CHANGE_HEARING_TIME_BUTTON,
    element: ChangeHearingTime
  },
  change_email_or_timezone: {
    // The modal title changes depending on the which updates the user made to the
    // virtual hearing.
    title: ({
      representativeEmailEdited,
      representativeTzEdited,
      appellantEmailEdited,
      appellantTzEdited,
    }) => {
      const emailUpdated = appellantEmailEdited || representativeEmailEdited;
      const tzUpdated = appellantTzEdited || representativeTzEdited;

      if (emailUpdated && tzUpdated) {
        return COPY.VIRTUAL_HEARING_MODAL_UPDATE_GENERIC_TITLE;
      } else if (emailUpdated) {
        return COPY.VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_TITLE;
      }

      return COPY.VIRTUAL_HEARING_MODAL_UPDATE_TIMEZONE_TITLE;

    },
    intro: COPY.VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_INTRO,
    button: COPY.VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON,
    element: ChangeEmailOrTimezone
  }
};

const VirtualHearingModal = (props) => {
  const {
    closeModal,
    hearing,
    virtualHearing,
    reset,
    submit,
    type,
    representativeEmailEdited,
    representativeTzEdited,
    appellantEmailEdited,
    appellantTzEdited,
    scrollLock
  } = props;
  const [appellantEmailError, setAppellantEmailError] = useState(null);
  const [representativeEmailError, setRepresentativeEmailError] = useState(null);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const typeSettings = TYPES[type];
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);
  const modalTitle = sprintf(
    typeSettings.title({
      representativeEmailEdited,
      representativeTzEdited,
      appellantEmailEdited,
      appellantTzEdited
    }),
    { appellantTitle }
  );

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
        const msg = error.response?.body?.errors[0]?.message;
        const representativeEmailIsValid = msg?.indexOf('Representative') === -1;
        const appellantEmailIsValid = msg?.indexOf('Veteran') === -1 && msg?.indexOf('Appellant') === -1;

        setRepresentativeEmailError(representativeEmailIsValid ? null : INVALID_EMAIL_FORMAT);
        setAppellantEmailError(appellantEmailIsValid ? null : INVALID_EMAIL_FORMAT);
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
        title={modalTitle}
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
        scrollLock={scrollLock}
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
    representativeEmailAddress: PropTypes.string,
    veteranEmailAddress: PropTypes.string
  }).isRequired,
  type: PropTypes.oneOf(HEARING_CONVERSION_TYPES).isRequired,
  timeWasEdited: PropTypes.bool,
  representativeEmailEdited: PropTypes.bool,
  representativeTzEdited: PropTypes.bool,
  appellantEmailEdited: PropTypes.bool,
  appellantTzEdited: PropTypes.bool,
  update: PropTypes.func,
  submit: PropTypes.func,
  reset: PropTypes.func,
  closeModal: PropTypes.func,

  // Passthrough to `Modal` to enable/disable the `ScrollLock` element from displaying.
  scrollLock: PropTypes.bool
};

export default VirtualHearingModal;
