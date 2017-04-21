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
      <p className="logo-example">
        <Logo app="efolder" /><span>e-Folder Express</span>
      </p>
      <p className="logo-example">
        <Logo app="certification" /><span>Certification</span>
      </p>
      <p className="logo-example">
        <Logo app="dispatch" /><span>Dispatch</span>
      </p>
      <p className="logo-example">
        <Logo app="reader" /><span>Reader</span>
      </p>
      <p className="logo-example">
        <Logo app="feedback" /><span>Feedback</span>
      </p>
      <p className="logo-example">
        <Logo /><span>General Logo</span>
      </p>
    </div>;
  }
}
