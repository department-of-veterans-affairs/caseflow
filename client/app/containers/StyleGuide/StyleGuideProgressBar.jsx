import React from 'react';

// components
import ProgressBar from '../../components/ProgressBar';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default function StyleGuideProgressBar() {

  let sections = [
    {
      title: '1. Shopping Cart'
    },
    {
      title: '2. Checkout',
      current: true
    },
    {
      title: '3. Confirmation'
    }
  ];

  return <div>
      <StyleGuideComponentTitle
        title="Progress Bar"
        id="progress_bar"
        link="StyleGuideProgressBar.jsx"
      />
      <p>
        This text here is the placeholder description for the Progress Bar.
      </p>
      <ProgressBar
        sections = {sections}
      />
  </div>;

}
