import React from 'react';
import Checkbox from 'app/components/Checkbox';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from 'app/components/Button';
import TextareaField from 'app/components/TextareaField';

const Header = () => {
  /* eslint-disable max-len */
  return <div>
    <h1 id="#top"> Welcome to the VHA Help page! </h1>
    <p>Here you will find <a href="#training-videos"> Training Videos</a> and <a href="#faq"> Frequently Asked Questions (FAQs)</a> for Intake, as well as links to the Training Guide and the Quick Reference Guide </p>
  </div>;
};

const TrainingVideos = () => {
  return <div>
    <h1 id="training-videos"> Training Videos</h1>
    <p> Training video for business lines </p>
  </div>;
};

const FrequentlyAskedQuestions = () => {
  return <div>
    <h1 id="faq"> Frequently Asked Questions </h1>
  </div>;
};

const vhaProgramOfficeOptions = () => {
  return [
    {
      id: 'vhaCAMO',
      label: 'VHA CAMO'
    },
    {
      id: 'vhaCaregiverSupportProgram',
      label: 'VHA Caregiver Support Program'
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

// TODO: Move all the form logic into it's own controlled component either custom or using the useForm hook for react hook forms
// TODO: use the redux store value for this.
const programOfficeFeatureToggle = () => true;

const GeneralVHAAccess = () => {
  return <>
    <legend><strong>General Access</strong></legend>
    <Checkbox name="vhaAccess" label="VHA" />
  </>;
};

const SpecializedAccess = () => {
  return <>
    <legend><strong>Specialized Access</strong></legend>
    {programOfficeFeatureToggle() && <CheckboxGroup options={vhaProgramOfficeOptions()} onChange />}
  </>;
};

const MembershipRequestForm = () => {
  const submitDisabled = true;

  return <div>
    <h1> 1. How do I access the VHA team?</h1>
    <p> If you need access to a VHA team, please fill out the form below.</p>
    <h2>Select which VHA groups you need access to</h2>
    <form>
      <GeneralVHAAccess />
      <SpecializedAccess />
      <TextareaField
        label="Reason for access"
        name="context-and-instructions-textBox"
        optional
        // value={instructions}
        // onChange={(val) => setInstructions(val)}
        // errorMessage={highlightInvalid && !validInstructions() ? COPY.CAVC_INSTRUCTIONS_ERROR : null}
        // strongLabel
      />
      <SubmitButton disabled={submitDisabled} />
    </form>
  </div>;
};

const SubmitButton = ({ ...btnProps }) => {
  return (
    <Button name="submit-request" {...btnProps}>
      Submit
    </Button>
  );
};

const HelpDivider = () => {
  return <div className="cf-help-divider"></div>;
};

const VhaHelp = () => {

  return <div className="cf-help-content">
    <Header />
    <HelpDivider />
    <TrainingVideos />
    <HelpDivider />
    <FrequentlyAskedQuestions />
    <HelpDivider />
    <MembershipRequestForm />
  </div>;
};

export default VhaHelp;
