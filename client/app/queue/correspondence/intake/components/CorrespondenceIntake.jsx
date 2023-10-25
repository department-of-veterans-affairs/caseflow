import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import ProgressBar from 'app/components/ProgressBar';
import Button from '../../../../components/Button';

const progressBarSections = [
  {
    title: '1. Add Related Correspondence',
    current: false
  },
  {
    title: '2. Review Tasks & Appeals',
    current: true
  },
  {
    title: '3. Confirm',
    current: false
  },
];

export const CorrespondenceIntake = () => {
  const sections = useMemo(
    () =>
      progressBarSections.map(({ title, current }) => ({
        title,
        current
      })),
  );

  return <div>
    <ProgressBar sections={sections} />
    <Button
      name="Cancel"
      classNames={['cf-btn-link']} />
    <Button
      type="button"
      name="Continue"
      classNames={['cf-push-right']}>
        Continue
    </Button>
  </div>;
};
export default CorrespondenceIntake;

