import React from 'react';

// components
import ProgressBar from '../../components/ProgressBar';

export default function StyleGuideProgressBar() {

  return <div>
      <h2 id="progress_bar">Progress Bar</h2>
      <p>
        Something.
      </p>
      <ProgressBar
        sections = {
        [
          {
            activated: true,
            title: '1. Shopping Cart'
          },
          {
            activated: true,
            title: '2. Checkout'
          },
          {
            activated: false,
            title: '3. Confirmation'
          }
        ]
      }
      />
  </div>;

}
