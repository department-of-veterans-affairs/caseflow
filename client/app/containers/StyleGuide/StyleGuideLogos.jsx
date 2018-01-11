import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import CaseflowLogo from '../../components/CaseflowLogo';
// import { css } from 'glamor';

export default class StyleLogos extends React.PureComponent {
  render = () => {

    const logos = [
      {
        accentColor: '#844e9f',
        overlapColor: '#7a4b91',
        appName: 'Dispatch'
      },
      {
        accentColor: 'rgb(72, 144, 0)',
        overlapColor: 'rgb(72, 144, 0)',
        appName: 'Hearings Prep'
      },
      {
        accentColor: '#FFCC4E',
        overlapColor: '#CA9E00',
        appName: 'Intake'
      },
      {
        accentColor: '#417505',
        overlapColor: '#2D5104',
        appName: 'Reader'
      }
    ];

    // const logoWrapperStyles = css({
    //   display: 'flex',
    //   alignItems: 'center'
    // });    

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
        logos.map(({ appName, ...logoProps }) => <p key={appName}>
          <CaseflowLogo {...logoProps} /><strong>{appName}</strong>
        </p>)
      }
    </div>;
  }
}
