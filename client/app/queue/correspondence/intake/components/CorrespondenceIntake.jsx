import React, { useState } from 'react';
import ProgressBar from 'app/components/ProgressBar';
import Button from '../../../../components/Button';
import { css } from 'glamor';

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
    <ProgressBar sections={sections} />
    <a href="/queue/correspondence">
      <Button
        name="cancel"
        href="/queue/correspondence"
        classNames={['cf-btn-link']} />
    </a>
    <div >
      {currentStep > 1 &&
      <Button
        type="button"
        onClick={prevStep}
        name="back-button"
        classNames={['usa-button-secondary', 'button-back-button']}>
          Back
      </Button>}
      {currentStep < 3 &&
      <Button
        type="button"
        onClick={nextStep}
        name="continue"
        styling={css({ marginLeft: '1rem' })}
        classNames={['cf-right-side']}>
          Continue
      </Button>}
      {currentStep === 3 &&
      <Button
        type="button"
        name="Submit"
        styling={css({ marginLeft: '1rem' })}
        classNames={['cf-right-side']}>
          Submit
      </Button>}
    </div>
  </div>;
};

export default CorrespondenceIntake;

