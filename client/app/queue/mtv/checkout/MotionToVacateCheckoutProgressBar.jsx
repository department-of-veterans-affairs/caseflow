import React, { useMemo } from 'react';
import PropTypes from 'prop-types';

import ProgressBar from '../../../components/ProgressBar';
import { views } from './mtvCheckoutSteps';

const generateSections = (steps, current) =>
  steps.map((step, idx) => ({
    title: `${idx + 1}. ${views[step].title}`,
    current: step === current
  }));

export const MotionToVacateCheckoutProgressBar = ({ steps, current }) => {
  const sections = useMemo(() => generateSections(steps, current), [steps, current]);

  return <ProgressBar sections={sections} />;
};

MotionToVacateCheckoutProgressBar.propTypes = {
  steps: PropTypes.array.isRequired,
  current: PropTypes.string
};
