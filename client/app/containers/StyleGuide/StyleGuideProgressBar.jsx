import React from 'react';

// components
import ProgressBar from '../../components/ProgressBar';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default function StyleGuideProgressBar() {

  let sections = [
    {
      title: '1. Review Description'
    },
    {
      title: '2. Create End Product',
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
        The Caseflow App uses a minimal progress indicator to guide users through
        important tasks. This allows users to view where they are and what to expect
        in the process. Each task is labeled with a progress bar, number, and name.
      </p>
      <p>
        For contrast, <code>gray-dark</code> (#323A45) is for current and past
        completed steps while <code>gray-light</code> (#AEB0B5) is used for future steps.
        This color scheme also ensures compliance with 508 Accessibility and US
        Web Design Standards.
      </p>
      <ProgressBar
        sections = {sections}
      />
  </div>;

}
