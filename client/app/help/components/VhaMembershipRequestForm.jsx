import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import Checkbox from 'app/components/Checkbox';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from 'app/components/Button';
import TextareaField from 'app/components/TextareaField';
import Alert from '../../components/Alert';
import { find, some } from 'lodash';
import { css } from 'glamor';
import { VHA_PROGRAM_OFFICE_OPTIONS, VHA_CAMO_AND_CAREGIVER_OPTIONS } from '../constants';
import { VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE,
  VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE } from '../../../COPY';

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

  let memberOrRequestToPreDocketOrg = false;

  // Disables options based on the user organizations and pending membership requests
  const parsedOptions = specializedAccessOptions.map((obj) => {
    const foundOrganization = some(userOrganizations, (match) => match.name === obj.name);

    const foundMembershipRequest = some(organizationMembershipRequests, (match) => match.name === obj.name);

    if (foundOrganization || foundMembershipRequest) {
      memberOrRequestToPreDocketOrg = true;

      return { ...obj, disabled: true };
    }

    return obj;
  });

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

  // TODO: add a onsubmit to this button and potentially one to the form
  const SubmitButton = ({ ...btnProps }) => {
    return (
      <Button name="submit-request" {...btnProps}>
      Submit
      </Button>
    );
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
      <form className={checkboxDivStyling}>
        <GeneralVHAAccess vhaMember={memberOrOpenRequestToVha} />
        <SpecializedAccess checkboxOptions={parsedOptions} />
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
