import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import CaseflowLogo from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/CaseflowLogo';
import { LOGO_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

export default class StyleLogos extends React.PureComponent {
  render = () => {

    const logos = [
      {
        accentColor: LOGO_COLORS.DISPATCH.ACCENT,
        overlapColor: LOGO_COLORS.DISPATCH.OVERLAP,
        appName: 'Dispatch'
      },
      {
        accentColor: LOGO_COLORS.HEARINGS.ACCENT,
        overlapColor: LOGO_COLORS.HEARINGS.OVERLAP,
        appName: 'Hearings Prep'
      },
      {
        accentColor: LOGO_COLORS.INTAKE.ACCENT,
        overlapColor: LOGO_COLORS.INTAKE.OVERLAP,
        appName: 'Intake'
      },
      {
        accentColor: LOGO_COLORS.READER.ACCENT,
        overlapColor: LOGO_COLORS.READER.OVERLAP,
        appName: 'Reader'
      }
    ];

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
      {
        logos.map(({ appName, ...logoProps }) => <p key={appName} className="cf-styleguide-logo-row">
          <CaseflowLogo {...logoProps} /><strong>{appName}</strong>
        </p>)
      }
    </div>;
  }
}
