import React, { useMemo, useState } from 'react';
import ProgressBar from 'app/components/ProgressBar';
import Button from '../../../../components/Button';
import Table from '../../../../components/Table';
import Checkbox from '../../../../components/Checkbox';
import RadioField from '../../../../components/RadioField';

const progressBarSections = [
  {
    title: '1. Add Related Correspondence',
    step: 1
  },
  {
    title: '2. Review Tasks & Appeals',
    step: 2
  },
  {
    title: '3. Confirm',
    step: 3
  },
];

const priorMailAnswer = [
  { displayText: 'Yes',
    value: 'yes' },
  { displayText: 'No',
    value: 'no' }
];

export const CorrespondenceIntake = () => {
  const [currentStep, setCurrentStep] = useState(1);

  const nextStep = () => {
    if (currentStep < 3) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const sections = progressBarSections.map(({ title, step }) => ({
    title,
    current: (step === currentStep)
  }),
  );

  const [selectedValue, setSelectedValue] = useState('no');

  const handleRadioChange = (event) => {
    setSelectedValue(event);
  };

  const correspondenceColumns = [
    {
      valueName: 'checkbox'
    },
    {
      header: <h3>VA DOR</h3>,
      valueName: 'va_dor'
    },
    {
      header: <h3>Source Type</h3>,
      valueName: 'source_type'
    },
    {
      header: <h3>Package Document Type</h3>,
      valueName: 'package_document_type'
    },
    {
      header: <h3>Correspondence Type</h3>,
      valueName: 'correspondence_type'
    },
    {
      header: <h3>Notes</h3>,
      valueName: 'notes'
    }
  ];

  const correspondenceRowObjects = [
    {
      checkbox: <Checkbox name="1" hideLabel="true" />,
      va_dor: '09/14/2023' || 'Null',
      source_type: <a href="https://www.google.com">Mail</a> || 'Source Type Error',
      package_document_type: '10182' || 'Package Type Error',
      correspondence_type: 'Evidence or argument' || 'Correspondence Type Error',
      notes: 'This is an example of notes for correspondence' || 'Notes Error'
    },
    {
      checkbox: <Checkbox name="2" hideLabel="true" />,
      va_dor: '09/15/2023' || 'Null',
      source_type: <a href="https://www.google.com">Mail</a> || 'Source Type Error',
      package_document_type: '10182' || 'Package Type Error',
      correspondence_type: 'Evidence or argument' || 'Correspondence Type Error',
      notes: 'This is an example of notes for correspondence' || 'Notes Error'
    },
    {
      checkbox: <Checkbox name="3" hideLabel="true" />,
      va_dor: '09/16/2023' || 'Null',
      source_type: <a href="https://www.google.com">Mail</a> || 'Source Type Error',
      package_document_type: '10182' || 'Package Type Error',
      correspondence_type: 'Evidence or argument' || 'Correspondence Type Error',
      notes: 'This is an example of notes for correspondence' || 'Notes Error'
    },
  ];

  return <div>
    <ProgressBar
      sections={sections}
      classNames={['cf-progress-bar', 'cf-']}
      styling={{ style: { marginBottom: '5rem', float: 'right' } }} />
    {currentStep === 1 &&
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Add Related Correspondence</h1>
          <p>Add any related correspondence to the mail package that is in progress.</p>
          <br></br>
          <h2>Associate with prior Mail</h2>
          <p>Is this correspondence related to prior mail?</p>
          <RadioField
            name=""
            options={priorMailAnswer}
            value={selectedValue}
            onChange={handleRadioChange} />

          {selectedValue === 'yes' && (
            <div className="cf-app-segment cf-app-segment--alt">
              <p>Please select the prior mail to link to this correspondence</p>
              <p>Viewing 1-15 out of 200 total</p>
              <Table
                className="cf-borderless-rows"
                columns={correspondenceColumns}
                rowObjects={correspondenceRowObjects}
                summary="Correspondence Information"
                slowReRendersAreOk
              />
            </div>
          )}
        </div>
    }
    <div>
      <a href="/queue/correspondence">
        <Button
          name="Cancel"
          styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
          href="/queue/correspondence"
          classNames={['cf-btn-link', 'cf-left-side']} />
      </a>
      {currentStep < 3 &&
      <Button
        type="button"
        onClick={nextStep}
        name="continue"
        classNames={['cf-right-side']}>
          Continue
      </Button>}
      {currentStep === 3 &&
      <Button
        type="button"
        name="Submit"
        classNames={['cf-right-side']}>
          Submit
      </Button>}
      {currentStep > 1 &&
      <Button
        type="button"
        onClick={prevStep}
        name="back-button"
        styling={{ style: { marginRight: '2rem' } }}
        classNames={['usa-button-secondary', 'cf-right-side', 'usa-back-button']}>
          Back
      </Button>}
    </div>
  </div>;
};

export default CorrespondenceIntake;
