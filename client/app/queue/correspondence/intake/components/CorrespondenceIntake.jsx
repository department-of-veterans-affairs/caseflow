import React, { useState } from 'react';
import ProgressBar from 'app/components/ProgressBar';
import Button from '../../../../components/Button';

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
