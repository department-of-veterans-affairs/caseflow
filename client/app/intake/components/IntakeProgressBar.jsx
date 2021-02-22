import React, { useMemo } from 'react';
import { useLocation } from 'react-router-dom';
import ProgressBar from 'app/components/ProgressBar';
import { PAGE_PATHS } from 'app/intake/constants';

const progressBarSections = [
  {
    title: '1. Select Form',
    paths: [PAGE_PATHS.BEGIN],
  },
  {
    title: '2. Search',
    paths: [PAGE_PATHS.SEARCH],
  },
  {
    title: '3. Review',
    paths: [PAGE_PATHS.REVIEW, PAGE_PATHS.ADD_CLAIMANT, PAGE_PATHS.ADD_POWER_OF_ATTORNEY],
  },
  {
    title: '4. Add Issues',
    paths: [PAGE_PATHS.ADD_ISSUES, PAGE_PATHS.FINISH],
  },
  {
    title: '5. Confirmation',
    paths: [PAGE_PATHS.COMPLETED],
  },
];

export const IntakeProgressBar = () => {
  const { pathname } = useLocation();
  const sections = useMemo(
    () =>
      progressBarSections.map(({ title, paths }) => ({
        title,
        current: paths?.includes(pathname),
      })),
    [pathname]
  );

  return <ProgressBar sections={sections} />;
};

export default IntakeProgressBar;
