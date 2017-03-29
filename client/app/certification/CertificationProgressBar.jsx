import React from 'react';
import ProgressBar from '../components/ProgressBar';

// TODO: use the redux store to grab data and render this.
const CertificationProgressBar = () => {
  return <ProgressBar
    sections = {
    [
      {
        current: true,
        title: '1. Check Documents'
      },
      {
        title: '2. Confirm Hearing'
      },
      {
        title: '3. Confirmation'
      }
    ]
    }
  />;
};

export default CertificationProgressBar;
