import React from 'react';
import StyleGuideLogos from './StyleGuideLogos';

export default class StyleGuideBranding extends React.PureComponent {
  render = () => {
    return <div>
      <h2 id="branding">Branding</h2>
      <StyleGuideLogos />
    </div>;
  }
}
