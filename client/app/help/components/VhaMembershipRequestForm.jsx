import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import Checkbox from 'app/components/Checkbox';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from 'app/components/Button';
import TextareaField from 'app/components/TextareaField';
import Alert from '../../components/Alert';
import { find, some } from 'lodash';
import { css } from 'glamor';
import { VHA_PROGRAM_OFFICE_OPTIONS,
  VHA_CAMO_AND_CAREGIVER_OPTIONS,
  VHA_ORG_NAMES_TO_READABLE_NAMES } from '../constants';
import { VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE,
  VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE,
  VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE } from '../../../COPY';
import { setOrganizationMembershipRequests,
  setSuccessMessage,
  submitMembershipRequestForm,
  setErrorMessage } from '../helpApiSlice';
import { unwrapResult } from '@reduxjs/toolkit';
import { sprintf } from 'sprintf-js';

const checkboxDivStyling = css({
  '& .cf-form-checkboxes': { marginTop: '10px' },
  '& .checkbox': { marginTop: '0px' },
  '& .cf-form-checkbox label::before': { left: '0px' },
});

const alertBoxStyling = css({
  marginBottom: '3rem',
  '& .usa-alert': { backgroundPositionY: 'center' },
});

const VhaMembershipRequestForm = () => {
  // Redux selectors
  const programOfficeTeamManagementFeatureToggle = useSelector(
    (state) => state.help.featureToggles.programOfficeTeamManagement
  );

  const userOrganizations = useSelector(
    (state) => state.help.userOrganizations
  );

  const organizationMembershipRequests = useSelector(
    (state) => state.help.organizationMembershipRequests
  );

  const dispatch = useDispatch();

  // Setup for all the predocket organizations checkbox options based on the feature toggle
  const specializedAccessOptions = programOfficeTeamManagementFeatureToggle ?
    [...VHA_CAMO_AND_CAREGIVER_OPTIONS, ...VHA_PROGRAM_OFFICE_OPTIONS] :
    VHA_CAMO_AND_CAREGIVER_OPTIONS;

  const [vhaAccess, setVhaAccess] = useState(false);
  const [preDocketOrgsAccess, setPreDocketOrgsAccess] = useState({});
  const [requestReason, setRequestReason] = useState('');

  const onVhaPredocketOrgsAccessChange = (evt) => {
    setPreDocketOrgsAccess({ ...preDocketOrgsAccess, [evt.target.id]: evt.target.checked });
  };

  const memberOrOpenRequestToVha = Boolean(find(userOrganizations, { name: 'Veterans Health Administration' }) ||
   find(organizationMembershipRequests, { name: 'Veterans Health Administration' }));

  const possibleOptions = useMemo(() => specializedAccessOptions.map((obj) => {
    const foundOrganization = some(userOrganizations, (match) => match.name === obj.name);

    const foundMembershipRequest = some(organizationMembershipRequests, (match) => match.name === obj.name);

    if (foundOrganization || foundMembershipRequest) {
      return { ...obj, disabled: true };
    }

    return obj;
  }), [userOrganizations, organizationMembershipRequests]);

  const memberOrRequestToPreDocketOrg = useMemo(() => {
    return Boolean(some(possibleOptions, (option) => option.disabled === true));
  }, [possibleOptions]);

  const GeneralVHAAccess = ({ vhaMember }) => {
    return <fieldset>
      <legend><strong>General Access</strong></legend>
      <Checkbox
        name="vhaAccess"
        label="VHA"
        disabled={vhaMember}
        onChange={(val) => setVhaAccess(val)}
        value={vhaAccess}
      />
    </fieldset>;
  };

  GeneralVHAAccess.propTypes = {
    vhaMember: PropTypes.bool
  };

  const SpecializedAccess = ({ checkboxOptions }) => {
    return (
      <fieldset>
        <legend><strong>Specialized Access</strong></legend>
        <CheckboxGroup
          name="preDocketOrgsAccess"
          hideLabel
          options={checkboxOptions}
          onChange={(val) => onVhaPredocketOrgsAccessChange(val)}
          values={preDocketOrgsAccess}
        />
      </fieldset>
    );
  };

  SpecializedAccess.propTypes = {
    checkboxOptions: PropTypes.arrayOf(
      PropTypes.object
    ).isRequired
  };

  const SubmitButton = ({ ...btnProps }) => {
    return (
      <Button name="submit-request" type="submit" {...btnProps}>
      Submit
      </Button>
    );
  };

  const resetMembershipRequestForm = () => {
    setVhaAccess(false);
    setPreDocketOrgsAccess({});
    setRequestReason('');
  };

  const formatSuccessMessage = (orgList) => {
    const formatter = new Intl.ListFormat('en', { style: 'long', type: 'conjunction' });
    const formattedOrgList = formatter.format(orgList.map((org) => VHA_ORG_NAMES_TO_READABLE_NAMES[org.name]));

    return sprintf(VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE, formattedOrgList);
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    // Build the form data from the state
    const membershipRequests = { vhaAccess, ...preDocketOrgsAccess };
    // Setup the form data in a typical json data format.
    const formData = { data: { membershipRequests, requestReason, organizationGroup: 'VHA' } };

    // TODO: Update unwrapResult to .unwrap() if the Redux Toolkit version is updated.
    dispatch(submitMembershipRequestForm(formData)).then(unwrapResult).
      then((values) => {
        const requestedOrgs = values.newMembershipRequests;
        const newOrgs = [...organizationMembershipRequests, ...requestedOrgs];

        dispatch(setSuccessMessage(formatSuccessMessage(requestedOrgs)));
        dispatch(setOrganizationMembershipRequests(newOrgs));
        resetMembershipRequestForm();
      }).
      catch((error) => {
        dispatch(setErrorMessage(error.message));
      });

  };

  const anyPredocketOrgSelected = useMemo(() => (
    find(preDocketOrgsAccess, (value) => value === true)),
  [preDocketOrgsAccess]);

  const vhaSelectedOrExistingMember = Boolean(memberOrOpenRequestToVha || vhaAccess);

  const submitDisabled = Boolean(memberOrOpenRequestToVha ?
    (!anyPredocketOrgSelected) :
    (!vhaAccess && !anyPredocketOrgSelected));

  const automaticVhaAccessNotice = anyPredocketOrgSelected && !vhaSelectedOrExistingMember;

  return (
    <>
      <h1> 1. How do I access the VHA team?</h1>
      <p> If you need access to a VHA team, please fill out the form below. </p>
      <h2> Select which VHA groups you need access to </h2>
      {(memberOrOpenRequestToVha || memberOrRequestToPreDocketOrg) &&
        <div className={alertBoxStyling}>
          <Alert
            type="info"
            message={VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE}
          />
        </div>
      }
      <form onSubmit={handleSubmit} className={checkboxDivStyling}>
        <GeneralVHAAccess vhaMember={memberOrOpenRequestToVha} />
        <SpecializedAccess checkboxOptions={possibleOptions} />
        <div style={{ minHeight: '51px' }}>
          { automaticVhaAccessNotice && (<p> {VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE} </p>)}
        </div>
        <TextareaField
          label="Reason for access"
          name="membership-request-instructions-textBox"
          optional
          value={requestReason}
          onChange={(val) => setRequestReason(val)}
        />
        <SubmitButton disabled={submitDisabled} />
      </form>
    </>
  );
};

export default VhaMembershipRequestForm;
