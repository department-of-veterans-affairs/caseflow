import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideColors extends React.Component {

  Colors = {
    Base: '#212121',
    'Gray-dark': '#323a45',
    Gray: '#5b616b',
    'Gray-lighter': '#d6d7d9',
    Primary: '#0071bc',
    White: '#ffffff',
    Secondary: '#e31c3d',
    Green: '#2e8540',
    'Secondary-lightest': '#f9dede',
    'Green-lightest': '#e7f4e4',
    'Primary-alt-lightest': '#e1f3f8',
    'Gold-lightest': '#fff1d2',
    Dispatch: '#844e9f',
    'eFolder Express': '#F0835e',
    Feedback: '#73e5d4',
    Certification: '#459fd7',
    Reader: '#417505'
  };

  Primary = [
    'Base',
    'Gray-dark',
    'Gray-lighter',
    'Primary',
    'White'
  ];

  Secondary = [
    'Secondary',
    'Green',
    'Secondary-lightest',
    'Green-lightest',
    'Primary-alt-lightest',
    'Gold-lightest'
  ];

  Logos = [
    'Dispatch',
    'eFolder Express',
    'Feedback',
    'Certification',
    'Reader'
  ];

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

  VAR_TITLE = 'Use this variable to refer to the hexadecimal value in your SASS files';

  render() {
    return <div>
      <StyleGuideComponentTitle
        title="Colors"
        id="colors"
        link="StyleGuideColors.jsx"
      />

      <p>
        Caseflow's palette borrows heavily from USWDS to communicate warmth and
        trustworthiness while meeting the highest standards of 508 color contrast
        requirements.
      </p>

      <h3>Palette</h3>

      <h4>Primary Colors</h4>

      <p>
        This palette’s primary colors are blue, gray, and white. Blue is commonly
        associated with trust, confidence, and sincerity; it is also used to represent
        calmness and responsibility.
      </p>

      <div className="sg-colors-swatches">
      {this.Primary.map((name, i) =>
        <div className="sg-colors-swatch" key={name + i}>
          <div style={{ background: this.Colors[name] }}></div>
          <b>{this.Colors[name]}</b>
          <p>{name}</p>
          <p title={this.VAR_TITLE}>{this.colorVar(name)}</p>
        </div>
      )}
      </div>

      <h4>Secondary Colors</h4>

      <p>
        These are accent colors to provide additional lightness and style to pages
        looking for a more modern flair. These colors should be used to highlight
        important features on a page, such as buttons, or for visual style elements,
        such as illustrations. They should be used sparingly and never draw the eye to
        more than one piece of information at a time.
      </p>

      <div className="sg-colors-swatches">
      {this.Secondary.slice(0, 2).map((name, i) =>
        <div className="sg-colors-swatch" key={name + i}>
          <div style={{ background: this.Colors[name] }}></div>
          <b>{this.Colors[name]}</b>
          <p>{name}</p>
          <p title={this.VAR_TITLE}>{this.colorVar(name)}</p>
        </div>
      )}
      </div>

      <div className="sg-colors-swatches">
      {this.Secondary.slice(2).map((name, i) =>
        <div className="sg-colors-swatch" key={name + i}>
          <div style={{ background: this.Colors[name] }}></div>
          <b>{this.Colors[name]}</b>
          <p>{name}</p>
          <p title={this.VAR_TITLE}>{this.colorVar(name)}</p>
        </div>
      )}
      </div>

      <h3>Logos</h3>

      <p>
        Logos are the only time Caseflow products use colors outside of Web Design
        Standards. These unique colors add a layer of modernism and fluidity to the
        Caseflow's core color themes of of trust, reliability, and transparency.
      </p>

      <div className="sg-colors-swatches">
      {this.Logos.map((name, i) =>
        <div className="sg-colors-swatch" key={name + i}>
          <div style={{ background: this.Colors[name] }}></div>
          <b>{this.Colors[name]}</b>
          <p>{name}</p>
        </div>
      )}
      </div>

      <h3>Text Accessibility</h3>

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

      {this.Combos.map((name, i) =>
        <div className="sg-colors-combo" key={name + i}
          style={{ color: this.Colors[name] }}>
          <b>{name.toLowerCase()} - on white</b>
        </div>
      )}
    </div>;
  }
}
