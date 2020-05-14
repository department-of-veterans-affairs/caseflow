import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { LOGO_COLORS } from '../../constants/AppConstants';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideColors extends React.PureComponent {

  Colors = {
    Base: '#212121',
    'Gray-dark': COLORS.GREY_DARK,
    Gray: '#5b616b',
    'Gray-light': '#aeb0b5',
    'Gray-lighter': COLORS.GREY_LIGHT,
    'Gray-lightest': '#f1f1f1',
    'Gray-warm-light': '#e4e2e0',
    Primary: '#0071bc',
    White: COLORS.WHITE,
    Secondary: '#e31c3d',
    Green: '#2e8540',
    'Primary-alt': COLORS.PRIMARY_ALT,
    'Secondary-lightest': '#f9dede',
    'Green-lightest': '#e7f4e4',
    'Primary-alt-lightest': '#e1f3f8',
    'Gold-lightest': '#fff1d2',
    Dispatch: LOGO_COLORS.DISPATCH.ACCENT,
    'eFolder Express': '#F0835e',
    Feedback: '#73e5d4',
    Certification: LOGO_COLORS.CERTIFICATION.ACCENT,
    Reader: LOGO_COLORS.READER.ACCENT,
    'Case Summary': LOGO_COLORS.INTAKE.ACCENT,
    Intake: LOGO_COLORS.INTAKE.ACCENT,
    Procedural: '#5a94ec',
    Medical: '#ff6868',
    'Other Evidence': '#3ad2cf'
  };

  Primary = [
    'Base',
    'Gray-dark',
    'Gray',
    'Gray-light',
    'Gray-lighter',
    'Gray-lightest',
    'Gray-warm-light',
    'Primary',
    'White'
  ];

  Secondary = [
    'Secondary',
    'Green',
    'Primary-alt',
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
    'Reader',
    'Intake'
  ];

  Reader = [
    'Case Summary',
    'Procedural',
    'Medical',
    'Other Evidence'
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

      <h3 id="palette">Palette</h3>

      <h4>Primary Colors</h4>

      <p>
        This palette’s primary colors are blue, gray, and white. Blue is commonly
        associated with trust, confidence, and sincerity; it is also used to represent
        calmness and responsibility.
      </p>

      <div className="sg-colors-swatches">
        {this.Primary.map((name) =>
          <div className="sg-colors-swatch" key={name}>
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
        {this.Secondary.slice(0, 3).map((name) =>
          <div className="sg-colors-swatch" key={name}>
            <div style={{ background: this.Colors[name] }}></div>
            <b>{this.Colors[name]}</b>
            <p>{name}</p>
            <p title={this.VAR_TITLE}>{this.colorVar(name)}</p>
          </div>
        )}
      </div>

      <div className="sg-colors-swatches">
        {this.Secondary.slice(3).map((name) =>
          <div className="sg-colors-swatch" key={name}>
            <div style={{ background: this.Colors[name] }}></div>
            <b>{this.Colors[name]}</b>
            <p>{name}</p>
            <p title={this.VAR_TITLE}>{this.colorVar(name)}</p>
          </div>
        )}
      </div>

      <h3 id="logo-colors">Logo Colors</h3>

      <p>
        Logos are the only time Caseflow products use colors outside of Web Design
        Standards. These unique colors add a layer of modernism and fluidity to the
        Caseflow's core color themes of trust, reliability, and transparency.
      </p>

      <div className="sg-colors-swatches">
        {this.Logos.map((name) =>
          <div className="sg-colors-swatch" key={name}>
            <div style={{ background: this.Colors[name] }}></div>
            <b>{this.Colors[name]}</b>
            <p>{name}</p>
          </div>
        )}
      </div>

      <h3 id="reader-categories">Reader Categories</h3>

      <div className="sg-colors-swatches">
        {this.Reader.map((name) =>
          <div className="sg-colors-swatch" key={name}>
            <div style={{ background: this.Colors[name] }}>
            </div>
            <b>{this.Colors[name]}</b>
            <p>{name}</p>
          </div>
        )}
      </div>
    </div>;
  }
}
