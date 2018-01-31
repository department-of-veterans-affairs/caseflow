import React from 'react';

// components
import StyleGuideComponentTitle from '../../../components/StyleGuideComponentTitle';

export default class TextAccessibility extends React.Component {

  Colors = {
    Base: '#212121',
    Gray: '#5b616b',
    Primary: '#0071bc',
    Secondary: '#e31c3d',
    Green: '#2e8540'
  };

  Combos = [
    'Base',
    'Gray',
    'Primary',
    'Secondary',
    'Green'
  ];

  colorVar = (name) => {
    return (`$color-${name}`).toLowerCase();
  };

  render() {
    return <div>
      <StyleGuideComponentTitle
        title="Text Accessibility"
        id="text-accessibility"
        link="Typography/TextAccessibility.jsx"
        isSubsection
      />

      <p>
        WCAG (Web Content Accessibility Guidelines) ensure that content is accessible by
        everyone, regardless of disability or user device. To meet these standards, text
        and interactive elements should have a color contrast ratio of at least 4.5:1.
        This ensures that viewers who cannot see the full color spectrum are able to
        read the text.
      </p>

      <p>
        The options below offer color palette combinations that fall within the range of
        Section 508 compliant foreground/background color contrast ratios. To ensure that
        text remains accessible, use only these permitted color combinations.
      </p>

      <p>
        If you choose to customize beyond this palette, this color contrast tool is a
        useful resource for testing the compliance of any color combination.
      </p>

      <h4>Fully Accessible Text Combinations</h4>

      {this.Combos.map((name) =>
        <div className="sg-colors-combo" key={name}
          style={{ color: this.Colors[name] }}>
          <b>{name.toLowerCase()} - on white</b>
        </div>
      )}
    </div>;
  }
}
