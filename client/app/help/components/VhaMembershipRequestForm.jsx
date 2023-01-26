import React, { useEffect, useMemo, useState } from 'react';
import Checkbox from 'app/components/Checkbox';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from 'app/components/Button';
import TextareaField from 'app/components/TextareaField';

const VhaMembershipRequestForm = (props) => {

  // TODO: Import these options from a constants/json file.
  const vhaProgramOfficeOptions = () => {
    return [
      {
        id: 'vhaCAMO',
        label: 'VHA CAMO',
      },
      {
        id: 'vhaCaregiverSupportProgram',
        label: 'VHA Caregiver Support Program',
      },
      {
        id: 'paymentOperationsManagement',
        label: 'Payment Operations Managment',
      },
      {
        id: 'veteranAndFamilyMembersProgram',
        label: 'Veteran and Family Members Program',
      },
      {
        id: 'memberServicesHealthEligibilityCenter',
        label: 'Member Services - Health Eligibility Center',
      },
      {
        id: 'memberServicesBeneficiaryTravel',
        label: 'Member Services - Beneficiary Travel',
      },
      {
        id: 'prosthetics',
        label: 'Prosthetics',
      }
    ];
  };

  const junk = vhaProgramOfficeOptions().reduce((acc, obj) => {
    // acc[obj.id] = obj;
    acc[obj.id] = false;

    return acc;
  }, {});

  // console.log(junk);

  // TODO: create state variables
  const [vhaAccess, setVhaAccess] = useState(false);
  const [programOfficesAccess, setProgramOfficesAccess] = useState(junk);

  const onVhaProgramOfficeAccessChange = (evt) => {
    console.log(evt.target);
    console.log(evt.target.checked);
    // console.log(!evt.target.checked);
    // evt.target.checked = true;
    // console.log(evt.target);
    // evt.target.checked = true;
    // console.log(programOfficesAccess);
    setProgramOfficesAccess({ ...programOfficesAccess, [evt.target.id]: evt.target.checked });
    // console.log(programOfficesAccess);
  };

  // const onVhaProgramOfficeAccessChange = (evt) => {
  //   setProgramOfficesAccess(evt);
  // };

  // TODO: create redux selectors

  let testValues = vhaProgramOfficeOptions().map((obj) => ({ [obj.id]: obj }));

  let newValues = {};

  // console.log(testValues);

  // vhaProgramOfficeOptions().forEach((item) => newValues[item.id] = true);

  // console.log(newValues);

  // console.log(Object.entries(newValues).filter((item) => item[1]).
  //   flatMap((item) => item[0]));

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
            options={vhaProgramOfficeOptions()}
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

  // TODO: Could also use redux actions to set the membership requests depending on the checkboxe clicks
  const submitDisabled = true;

  console.log(programOfficesAccess);
  // console.log(vhaAccess);

  return (
    <>
      <form>
        <GeneralVHAAccess />
        <SpecializedAccess />
        <TextareaField
          label="Reason for access"
          name="membership-request-instructions-textBox"
          optional
        // value={instructions}
        // onChange={(val) => setInstructions(val)}
        // errorMessage={highlightInvalid && !validInstructions() ? COPY.CAVC_INSTRUCTIONS_ERROR : null}
        // strongLabel
        />
        <SubmitButton disabled={submitDisabled} />
      </form>
    </>
  );
};

export default VhaMembershipRequestForm;
