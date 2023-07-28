import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import { isUndefined, get, omitBy } from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React, { useState, useContext, useEffect } from 'react';
import { sprintf } from 'sprintf-js';

import { DetailsHeader } from './details/DetailsHeader';
import { HearingConversion } from './HearingConversion';
import {
  HearingsFormContext,
  updateHearingDispatcher,
  RESET_HEARING
} from '../contexts/HearingsFormContext';
import { HearingsUserContext } from '../contexts/HearingsUserContext';
import {
  deepDiff,
  getChanges,
  getConvertToVirtualChanges,
  getAppellantTitle,
  processAlerts,
  startPolling,
  parseVirtualHearingErrors,
  allDetailsDropdownOptions,
  hearingRequestTypeOptions,
  hearingRequestTypeCurrentOption
} from '../utils';
import { inputFix } from './details/style';
import {
  onReceiveAlerts,
  onReceiveTransitioningAlert,
  transitionAlert,
  clearAlerts
} from '../../components/common/actions';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import DetailsForm from './details/DetailsForm';
import UserAlerts from '../../components/UserAlerts';
import EmailConfirmationModal from './EmailConfirmationModal';
import COPY from '../../../COPY';
import { VIRTUAL_HEARING_LABEL } from '../constants';

/**
 * Hearing Details Component
 * @param {Object} props -- React props inherited from client/app/hearings/containers/DetailsContainer.jsx
 * @component
 */
const HearingDetails = (props) => {
  // Map the state and dispatch to relevant names
  const { state: { initialHearing, hearing, formsUpdated }, dispatch } = useContext(HearingsFormContext);
  const { userVsoEmployee } = useContext(HearingsUserContext);

  // Create the update hearing dispatcher
  const updateHearing = updateHearingDispatcher(hearing, dispatch);

  // Pull out the inherited state to handle actions
  const { saveHearing, goBack, disabled } = props;

  // Determine whether this is a legacy hearing
  const isLegacy = hearing?.docketName !== 'hearing';

  // Establish the state of the hearing details
  const [converting, convertHearing] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [virtualHearingErrors, setVirtualHearingErrors] = useState({});
  const [emailConfirmationModalOpen, setEmailConfirmationModalOpen] = useState(false);
  const [emailConfirmationModalType, setEmailConfirmationModalType] = useState(null);
  const [shouldStartPolling, setShouldStartPolling] = useState(null);
  const [VSOConvertSuccessful, setVSOConvertSuccessful] = useState(false);
  const [isValidEmail, setIsValidEmail] = useState(hearing?.appellantEmailAddress);
  const [formSubmittable, setFormSubmittable] = useState(false);
  const [hearingConversionCheckboxes, setHearingConversionCheckboxes] = useState(false);

  const canSubmit = () => {
    let emailFieldsValid = (
      isValidEmail &&
      hearing?.appellantEmailAddress &&
      hearing?.appellantTz &&
      hearing?.representativeTz &&
      hearing?.appellantEmailAddress === hearing?.appellantConfirmEmailAddress &&
      hearingConversionCheckboxes
    );

    setFormSubmittable(emailFieldsValid);
  };

  useEffect(() => {
    canSubmit();
  }, [hearing, isValidEmail, hearingConversionCheckboxes]);

  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);
  const convertingToVirtual = converting === 'change_to_virtual';
  // Method to reset the state
  const resetState = (resetHearingObj) => {
    // Reset the state
    setVirtualHearingErrors({});
    convertHearing('');
    setLoading(false);
    setError(false);

    // reset hearing
    if (resetHearingObj) {
      dispatch({ type: RESET_HEARING, payload: resetHearingObj });
    }

    // Focus the top of the page
    window.scrollTo(0, 0);
  };

  // Create an effect to remove stale alerts on unmount
  useEffect(() => () => props.clearAlerts(), []);

  // Set hearing attrs to that of a virtual one if the user is a VSO employee
  // since they will skip interacting with the hearing type dropdown.
  useEffect(() => {
    if (userVsoEmployee) {
      convertHearing('change_to_virtual');
      updateHearing('virtualHearing', { requestCancelled: false });
    }
  }, []);

  const openEmailConfirmationModal = ({ type }) => {
    setEmailConfirmationModalOpen(true);
    setEmailConfirmationModalType(type);
  };

  const closeEmailConfirmationModal = () => setEmailConfirmationModalOpen(false);

  const getEditedEmailsAndTz = () => {
    const changes = deepDiff(
      initialHearing,
      hearing || {}
    );

    return {
      appellantEmailEdited: !isUndefined(changes.appellantEmailAddress),
      representativeEmailEdited: !isUndefined(changes.representativeEmailAddress),
      representativeTzEdited: !isUndefined(changes.representativeTz),
      appellantTzEdited: !isUndefined(changes.appellantTz)
    };
  };

  const filterEmailAttribute = (email) => {
    if (convertingToVirtual) {
      return Object.keys(email).includes('email_address') && email.email_address;
    }

    return Object.keys(email).includes('email_address') || Object.keys(email).includes('timezone');
  };

  const handleCancelButton = () => {
    if (userVsoEmployee) {
      goBack();
    } else if (converting) {
      resetState(initialHearing);
    } else {
      goBack();
    }
  };

  // VSO convert success banner
  const getSuccessMsg = () => {
    const appellantFullName = `${hearing?.appellantFirstName} ${hearing?.appellantLastName}`;
    const veteranFullName = `${hearing?.veteranFirstName} ${hearing?.veteranLastName}`;
    const title = sprintf(
      COPY.CONVERT_HEARING_TYPE_SUCCESS,
      hearing?.appellantIsNotVeteran ? appellantFullName : veteranFullName,
      'virtual'
    );
    const detail = COPY.VSO_CONVERT_HEARING_TYPE_SUCCESS_DETAIL;

    return { title, detail };
  };

  const submit = async (editedEmailsAndTz) => {
    try {
      // Determine the current state and whether to error
      const noAppellantEmail = !hearing?.appellantEmailAddress;

      const noRepTimezone = convertingToVirtual ?
        !hearing?.representativeTz && hearing?.representativeEmailAddress :
        editedEmailsAndTz?.representativeEmailEdited && !hearing?.representativeTz;

      const noAppellantTimezone = convertingToVirtual ? !hearing?.appellantTz :
        editedEmailsAndTz?.appellantEmailEdited && !hearing?.appellantTz;

      const emailUpdated = (
        editedEmailsAndTz?.appellantEmailEdited ||
        (editedEmailsAndTz?.representativeEmailEdited && hearing?.representativeEmailAddress)
      );
      const timezoneUpdated = editedEmailsAndTz?.representativeTzEdited || editedEmailsAndTz?.appellantTzEdited;
      const errors = noAppellantEmail || noAppellantTimezone || noRepTimezone;
      const virtualHearingCheck = hearing.isVirtual || convertingToVirtual;

      if (errors && virtualHearingCheck) {
        // Set the Virtual Hearing errors
        setVirtualHearingErrors({
          [noAppellantEmail && 'appellantEmailAddress']: `${appellantTitle} email is required`,
          [noRepTimezone && 'representativeTz']: COPY.VIRTUAL_HEARING_TIMEZONE_REQUIRED,
          [noAppellantTimezone && 'appellantTz']: COPY.VIRTUAL_HEARING_TIMEZONE_REQUIRED
        });

        // Focus to the error
        return document.getElementById('email-section').scrollIntoView();
      } else if ((emailUpdated || timezoneUpdated) && !converting && hearing.isVirtual) {
        return openEmailConfirmationModal({ type: 'change_email_or_timezone' });
      }

      // Only send updated properties unless converting to virtual, then send everything.
      const { virtualHearing, transcription, ...hearingChanges } = convertingToVirtual ?
        getConvertToVirtualChanges(
          initialHearing,
          hearing
        ) :
        getChanges(
          initialHearing,
          hearing
        );

      const emailRecipientAttributes = [
        omitBy(
          {
            id: hearing?.appellantEmailId,
            timezone: hearingChanges?.appellantTz,
            email_address: hearingChanges?.appellantEmailAddress,
            type: 'AppellantHearingEmailRecipient'
          }, isUndefined
        ),
        omitBy(
          {
            id: hearing?.representativeEmailId,
            timezone: hearingChanges?.representativeTz,
            email_address: hearingChanges?.representativeEmailAddress,
            type: 'RepresentativeHearingEmailRecipient'
          }, isUndefined
        )
      ].filter((email) => filterEmailAttribute(email));

      // Put the UI into a loading state
      setLoading(true);

      // Save the hearing
      const response = await saveHearing({
        hearing: {
          ...(hearingChanges || {}),
          // Always send full transcription details because a new record is created each update
          transcription_attributes: transcription ? hearing.transcription : {},
          virtual_hearing_attributes: virtualHearing || {},
          email_recipients_attributes: emailRecipientAttributes.length ? emailRecipientAttributes : {},
        },
      });
      const hearingResp = ApiUtil.convertToCamelCase(response.body?.data);

      const alerts = response.body?.alerts;

      if (alerts && !userVsoEmployee) {
        processAlerts(alerts, props, setShouldStartPolling);
      }

      if (userVsoEmployee && convertingToVirtual) {
        // Store success message and Redirect back to the Case Details Page
        localStorage.setItem('VSOSuccessMsg', JSON.stringify(getSuccessMsg()));
        setVSOConvertSuccessful(true);
      } else {
        // Reset the state
        resetState(hearingResp);
      }
    } catch (respError) {
      const code = get(respError, 'response.body.errors[0].code') || '';

      // Retrieve the error message from the body
      const msg = respError?.response?.body?.errors.length > 0 && respError?.response?.body?.errors[0]?.message;

      // Set the state with the error
      setLoading(false);

      // email validations should be thrown inline
      if (code === 1002) {
        const errors = parseVirtualHearingErrors(msg);

        document.getElementById('email-section').scrollIntoView();

        setVirtualHearingErrors(errors);
      } else {
        setError(msg);
      }
    }
  };

  const poll = () => startPolling(hearing, {
    resetState,
    setShouldStartPolling,
    dispatch,
    props
  });

  const allDropdownOptions = allDetailsDropdownOptions(hearing);

  const hearingRequestTypeDropdownCurrentOption = hearingRequestTypeCurrentOption(
    allDropdownOptions,
    hearing?.virtualHearing
  );

  const hearingRequestTypeDropdownOptions = hearingRequestTypeOptions(
    allDropdownOptions,
    hearingRequestTypeDropdownCurrentOption
  );

  const detailsRequestTypeDropdownOnchange = (selectedOption) => {
    const type = selectedOption.label === VIRTUAL_HEARING_LABEL ? 'change_to_virtual' : 'change_from_virtual';

    convertHearing(type);
    updateHearing(
      'virtualHearing',
      {
        requestCancelled: selectedOption.label !== VIRTUAL_HEARING_LABEL,
        jobCompleted: false
      });
  };

  const editedEmailsAndTz = getEditedEmailsAndTz();
  const convertLabel = convertingToVirtual ?
    sprintf(COPY.CONVERT_HEARING_TITLE, 'Virtual') : sprintf(COPY.CONVERT_HEARING_TITLE, hearing.readableRequestType);

  if (VSOConvertSuccessful && userVsoEmployee) {
    // Construct the URL to redirect
    const baseUrl = `${window.location.origin}/queue/appeals`;

    window.location.href = `${baseUrl}/${hearing.appealExternalId}`;
  }

  return (
    <React.Fragment>
      <UserAlerts />
      {error && (
        <div>
          <Alert
            type="error"
            title={error === '' ? COPY.FAILED_HEARING_UPDATE : error}
          />
        </div>
      )}
      {converting ? (
        <HearingConversion
          title={convertLabel}
          type={converting}
          update={updateHearing}
          hearing={hearing}
          scheduledFor={hearing?.scheduledFor}
          errors={virtualHearingErrors}
          userVsoEmployee={userVsoEmployee}
          setIsValidEmail={setIsValidEmail}
          updateCheckboxes={setHearingConversionCheckboxes}
        />
      ) : (
        <AppSegment filledBackground>
          <div {...inputFix}>
            <DetailsHeader
              aod={hearing?.aod}
              disposition={hearing?.disposition}
              docketName={hearing?.docketName}
              docketNumber={hearing?.docketNumber}
              isVirtual={hearing?.isVirtual}
              hearingDayId={hearing?.hearingDayId}
              readableLocation={hearing?.readableLocation}
              readableRequestType={hearing?.readableRequestType}
              regionalOfficeName={hearing?.regionalOfficeName}
              scheduledFor={hearing?.scheduledFor}
              veteranFileNumber={hearing?.veteranFileNumber}
              veteranFirstName={hearing?.veteranFirstName}
              veteranLastName={hearing?.veteranLastName}
              hearing={hearing}
            />
            <DetailsForm
              hearing={hearing}
              initialHearing={initialHearing}
              errors={virtualHearingErrors}
              isLegacy={isLegacy}
              readOnly={disabled}
              hearingRequestTypeDropdownOptions={hearingRequestTypeDropdownOptions}
              hearingRequestTypeDropdownCurrentOption={hearingRequestTypeDropdownCurrentOption}
              hearingRequestTypeDropdownOnchange={detailsRequestTypeDropdownOnchange}
              update={updateHearing}
            />
            {shouldStartPolling && poll()}
          </div>
        </AppSegment>
      )}
      <div {...css({ overflow: 'hidden' })}>
        <Button
          id="Cancel"
          name="Cancel"
          linkStyling
          onClick={handleCancelButton}
          styling={css({ float: 'left', paddingLeft: 0, paddingRight: 0 })}
        >
          Cancel
        </Button>
        <span {...css({ float: 'right' })}>
          <Button
            id="Save"
            name="Save"
            disabled={!formsUpdated ||
              (disabled && !userVsoEmployee) ||
              (!formSubmittable && userVsoEmployee)
            }
            loading={loading}
            className="usa-button"
            onClick={async () => await submit(editedEmailsAndTz)}
          >
            {converting ? convertLabel : 'Save'}
          </Button>
        </span>
      </div>
      {emailConfirmationModalOpen && (
        <EmailConfirmationModal
          hearing={hearing}
          virtualHearing={hearing?.virtualHearing}
          update={updateHearing}
          submit={submit}
          closeModal={closeEmailConfirmationModal}
          reset={() => resetState(initialHearing)}
          type={emailConfirmationModalType}
          {...editedEmailsAndTz}
        />
      )}
    </React.Fragment>
  );
};

HearingDetails.propTypes = {
  saveHearing: PropTypes.func,
  goBack: PropTypes.func,
  disabled: PropTypes.bool,
  onReceiveAlerts: PropTypes.func,
  onReceiveTransitioningAlert: PropTypes.func,
  transitionAlert: PropTypes.func,
  clearAlerts: PropTypes.func
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    clearAlerts,
    onReceiveAlerts,
    onReceiveTransitioningAlert,
    transitionAlert },
  dispatch);

export default connect(
  null,
  mapDispatchToProps
)(HearingDetails);
