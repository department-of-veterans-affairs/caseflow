import React, { useMemo, useState } from 'react';
import ProgressBar from 'app/components/ProgressBar';
import Button from '../../../../components/Button';
import RadioField from '../../../../components/RadioField';

const progressBarSections = [
  {
    title: '1. Add Related Correspondence',
    current: true,
    step: 1
  },
  {
    title: '2. Review Tasks & Appeals',
    current: false,
    step: 2
  },
  {
    title: '3. Confirm',
    current: false,
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

  return <div>
    <ProgressBar
      sections={sections}
      classNames={['cf-progress-bar', 'cf-']}
      styling={{ style: { marginBottom: '5rem', float: 'right' } }} />
    <div>
      <a href="/queue/correspondence">
        <Button
          name="Cancel"
          styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
          href="/queue/correspondence"
          classNames={['cf-btn-link', 'cf-left-side']} />
      </a>
      {currentStep === 1 &&
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Add Related Correspondence</h1>
          <p>Add any related correspondence to the mail package that is in progress.</p>

          <h3>Associate with prior Mail</h3>

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
            </div>
          )}
        </div>
      }
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
