import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import ProgressBar from 'app/components/ProgressBar';

const progressBarSections = [
  {
    title: '1. Select Form'
  },
  {
    title: '2. Search'
  },
  {
    title: '3. Review'
  },
  {
    title: '4. Add Issues'
  },
  {
    title: '5. Confirmation'
  },
];

export const CorrespondenceIntake = () => {
  const sections = useMemo(
    () =>
      progressBarSections.map(({ title }) => ({
        title,
      })),
  );

  return <ProgressBar sections={sections} />;
};
export default CorrespondenceIntake;

