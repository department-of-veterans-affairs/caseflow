import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import Logo from '../../components/Logo';

export default class StyleLogos extends React.Component {
  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Logos"
        id="logos"
        link="StyleGuideLogos.jsx"
      />
      <p>
        The Caseflow logo, also known as the “Starwave”, is a minimal
        guilloche pattern that is meant to communicate security, fluidity,
        integration, dynamism, transparency, intuitiveness, and modernism.
        Each Caseflow application has it’s own unique accent color but the
        base color remains the same, gray-lighter.
      </p>
      <p>
        When refering to the whole Caseflow system, you should use the
        non-colored Caseflow logo.
      </p>
      <p>
        <Logo app="efolder" /><b>eFolder Express</b>
      </p>
      <p>
        <Logo app="certification" /><b>Certification</b>
      </p>
      <p>
        <Logo app="dispatch" /><b>Dispatch</b>
      </p>
      <p>
        <Logo app="reader" /><b>Reader</b>
      </p>
      <p>
        <Logo app="intake" /><b>Intake</b>
      </p>
      <p>
        <Logo app="feedback" /><b>Feedback</b>
      </p>
      <p>
        <Logo /><b>General Logo</b>
      </p>
    </div>;
  }
}
