import React, { useMemo } from 'react';
import { useLocation } from 'react-router-dom';
import ProgressBar from 'app/components/ProgressBar';
import { PAGE_PATHS } from '../constants';

const progressBarSections = [
  {
    title: '1. Create new appeal stream',
    paths: [PAGE_PATHS.CREATE],
  },
  {
    title: '2. Review and confirm',
    paths: [PAGE_PATHS.REVIEW],
  },
];

export const SplitAppealProgressBar = () => {
  const { pathname } = useLocation();
  const sections = useMemo(
    () =>
      progressBarSections.map(({ title, paths }) => ({
        title,
        current: pathname?.includes(paths),
      })),
    [pathname]
  );

  return <ProgressBar sections={sections} />;
};

export default SplitAppealProgressBar;
