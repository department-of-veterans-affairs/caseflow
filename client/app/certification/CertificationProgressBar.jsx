import React from 'react';
import ProgressBar from '../components/ProgressBar';

// TODO: use the redux store to grab data and render this.
const CertificationProgressBar = ({ match }) => {
  return <ProgressBar
    sections = {
    [
      {
        activated: true,
        title: '1. Check Documents'
      },
      {
        activated: false,
        title: '2. Confirm Hearing'
      },
      {
        activated: false,
        title: '3. Confirmation'
      }
    ]
    }
  />;
};

export default CertificationProgressBar;
