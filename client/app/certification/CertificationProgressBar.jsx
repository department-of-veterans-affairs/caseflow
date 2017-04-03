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
        title: '2. Confirm Case Details'
      },
      {
        title: '3. Confirm Hearing'
      },
      {
        title: '4. Confirmation'
      }
    ]
    }
  />;
};

export default CertificationProgressBar;
