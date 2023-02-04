import React, { useEffect, useMemo, useState } from 'react';
import { useSelector } from 'react-redux';
import Checkbox from 'app/components/Checkbox';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from 'app/components/Button';
import TextareaField from 'app/components/TextareaField';
import Alert from '../../components/Alert';
import { find } from 'lodash';
import { VHA_PROGRAM_OFFICE_OPTIONS, VHA_NOTICE_TEXT, VHA_RADIO_DISABLED_INFO_TEXT } from '../constants';
import { bool } from 'prop-types';

// TODO: Make this MembershipRequestForm generic instead of VHA only?
const VhaMembershipRequestForm = (props) => {

  // TODO: preparse VHA_PROGRAM_OFFICE_OPTIONS
  // Add disabled to the objects based on the organizations and membership requests

  // TODO: Figure out if Memo matters here or not
  // I dont think it does since useState won't be initialized more than once.
  const parsedIssues = useMemo(() => {
    VHA_PROGRAM_OFFICE_OPTIONS.reduce((acc, obj) => {
      acc[obj.id] = false;

      return acc;
    }, {});
  }, [VHA_PROGRAM_OFFICE_OPTIONS]);

  // TODO: create state variables
  const [vhaAccess, setVhaAccess] = useState(false);
  const [programOfficesAccess, setProgramOfficesAccess] = useState(parsedIssues);
  const [requestReason, setRequestReason] = useState('');

  const onVhaProgramOfficeAccessChange = (evt) => {
    setProgramOfficesAccess({ ...programOfficesAccess, [evt.target.id]: evt.target.checked });
  };

  // TODO: useMemo/useEffect hooks based on redux and state

  // TODO: Might move these into a selectors file
  // Redux Selector for the program_office_team_management feature toggle
  const programOfficeTeamManagementFeatureToggle = useSelector(
    (state) => state.help.featureToggles.programOfficeTeamManagement
  );

  const userOrganizations = useSelector(
    (state) => state.help.userOrganizations
  );

  const organizationMembershipRequests = useSelector(
    (state) => state.help.organizationMembershipRequests
  );

  const memberOrOpenRequestToVha = useMemo(() => {
    Boolean(find(userOrganizations, { name: 'Veterans Health Administration' }));
  }, [userOrganizations]);

  // TODO: This needs to correspond to the state of the checkboxes in some way
  // Parse the options themselves and make a new options
  // Based on the redux values for organizations and membership requests
  // With the objects having the disabled: true if they exist in those redux stores
  // Not sure how to match them up yet. Maybe id
  const memberOfProgramOffices = false;

  // TODO: Need to get the ProgramOffices for Vha from the backend instead of hard coding it here.
  // Not sure what the best way to group these is. Maybe based on database id? Idk
  const vhaCamoName = 'VHA CAMO';
  const vhaCaregiverName = 'VHA Caregiver Support Program';

  const programOfficeNames = ['Community Care - Payment Operations Management',
    'Community Care - Veteran and Family Members Program',
    'Member Services - Health Eligibility Center',
    'Member Services - Beneficiary Travel',
    'Prosthetics'];

  const allOfficeNames = [vhaCamoName, vhaCaregiverName] + programOfficeNames;

  const GeneralVHAAccess = ({ vhaMember }) => {
    return <>
      <legend><strong>General Access</strong></legend>
      <Checkbox
        name="vhaAccess"
        label="VHA"
        disabled={vhaMember}
        onChange={(val) => setVhaAccess(val)}
        value={vhaAccess}
      />
    </>;
  };

  GeneralVHAAccess.propTypes = {
    vhaMember: bool
  };

  const SpecializedAccess = () => {
    return (
      <>
        { programOfficeTeamManagementFeatureToggle && <>
          <legend><strong>Specialized Access</strong></legend>
          <CheckboxGroup
            name="programOfficesAccess"
            hideLabel
            options={VHA_PROGRAM_OFFICE_OPTIONS}
            onChange={(val) => onVhaProgramOfficeAccessChange(val)}
            values={programOfficesAccess}
          />
        </>
        }
      </>
    );
  };

  // TODO: add a onsubmit to this button and potentially one to the form?
  const SubmitButton = ({ ...btnProps }) => {
    return (
      <Button name="submit-request" {...btnProps}>
      Submit
      </Button>
    );
  };

  // TODO: Need to change this based on the feature toggle
  // Maybe not though. It might be fine since they won't be visable and will be set to false anyhow?
  const anyProgramOfficeSelected = useMemo(() => (
    find(programOfficesAccess, (value) => value === true)),
  [programOfficesAccess]);

  const vhaSelectedOrExistingMember = Boolean(memberOrOpenRequestToVha || vhaAccess);

  const submitDisabled = Boolean(memberOrOpenRequestToVha ?
    (!anyProgramOfficeSelected) :
    (!vhaAccess && !anyProgramOfficeSelected));

  const automaticVhaAccessNotice = anyProgramOfficeSelected && vhaSelectedOrExistingMember;

  // console.log(programOfficesAccess);
  console.log(`VhaAccess aka checkbox is checked: ${vhaAccess}`);
  console.log(`anyProgramOfficeSelected: ${Boolean(anyProgramOfficeSelected)}`);
  // console.log(requestReason);
  console.log(`Member or open request to Vha: ${Boolean(memberOrOpenRequestToVha)}`);
  console.log(`Submit disabled: ${submitDisabled}`);
  console.log(`vhaSelectedOrExistingMember: ${vhaSelectedOrExistingMember}`);

  // TODO: Maybe move these strings to the constants file
  // TODO: Fix the page moving for the paragraph notice if I can. It's a bit jarring.
  return (
    <>
      <h1> 1. How do I access the VHA team?</h1>
      <p> If you need access to a VHA team, please fill out the form below. </p>
      <h2> Select which VHA groups you need access to </h2>
      {memberOrOpenRequestToVha &&
        <div style={{ marginBottom: '3rem' }}>
          <Alert
            type="info"
            message={VHA_RADIO_DISABLED_INFO_TEXT}
          />
        </div>
      }
      <form>
        <GeneralVHAAccess vhaMember={memberOrOpenRequestToVha} />
        <SpecializedAccess />
        <p style={{ display: automaticVhaAccessNotice ? 'block' : 'none' }}> {VHA_NOTICE_TEXT} </p>
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
