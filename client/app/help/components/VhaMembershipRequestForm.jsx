import React, { useEffect, useMemo, useState } from 'react';
import Checkbox from 'app/components/Checkbox';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from 'app/components/Button';
import TextareaField from 'app/components/TextareaField';
import Alert from '../../components/Alert';
import { find } from 'lodash';
import { VHA_PROGRAM_OFFICE_OPTIONS, VHA_NOTICE_TEXT } from '../constants';

const VhaMembershipRequestForm = (props) => {

  // TODO: Figure out if Memo matters here or not
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

  // TODO: decide if this correct based on the redux selector for feature toggles.
  const programOfficeFeatureToggle = () => true;

  const GeneralVHAAccess = () => {
    return <>
      <legend><strong>General Access</strong></legend>
      <Checkbox
        name="vhaAccess"
        label="VHA"
        onChange={(val) => setVhaAccess(val)}
        value={vhaAccess}
      />
    </>;
  };

  const SpecializedAccess = () => {
    return (
      <>
        { programOfficeFeatureToggle() && <>
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

  // TODO: add a onsubmit to this button and potentially one to the form
  const SubmitButton = ({ ...btnProps }) => {
    return (
      <Button name="submit-request" {...btnProps}>
      Submit
      </Button>
    );
  };

  // TODO: derive this logic based on radio field options
  // If VHA is selected allow it through
  // If VHA was already selected then require one additional checkbox? based on redux store org/requests
  // If the user is already a member of vha check the box and disable the button

  // TODO: make this update based on redux or on the clicked boxes assuming redux populates those
  // Memo this or figure it out in ruby and give it to redux instead of figuring it out in javascript
  const memberOrOpenRequestToVha = true;

  const anyProgramOfficeSelected = useMemo(() => (
    find(programOfficesAccess, (value) => value === true)),
  [programOfficesAccess]);

  // TODO: Could also use redux actions to set the membership requests depending on the checkbox clicks
  const submitDisabled = (!vhaAccess && !memberOrOpenRequestToVha) ||
   (!anyProgramOfficeSelected && memberOrOpenRequestToVha);

  const automaticVhaAccessNotice = anyProgramOfficeSelected && !vhaAccess;
  // console.log(programOfficesAccess);
  // console.log(vhaAccess);
  // console.log(requestReason);
  // console.log(memberOrRequestToVha);

  return (
    <>
      <h1> 1. How do I access the VHA team?</h1>
      <p> If you need access to a VHA team, please fill out the form below. </p>
      <h2> Select which VHA groups you need access to </h2>
      {memberOrOpenRequestToVha &&
        <div style={{ marginBottom: '3rem' }}>
          <Alert
            type="info"
            message="Options are disabled if you have a pending request or are already a member of the group."
          />
        </div>
      }
      <form>
        <GeneralVHAAccess />
        <SpecializedAccess />
        {automaticVhaAccessNotice && <p> {VHA_NOTICE_TEXT} </p>}
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
