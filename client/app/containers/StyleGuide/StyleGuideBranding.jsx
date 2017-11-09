import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import StyleGuideLogos from './StyleGuideLogos';


export default class StyleGuideBranding extends React.Component {
  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Branding"
        id="branding"
        link="StyleGuideBranding.jsx"
      />
   <StyleGuideLogos />

  </div>;
  }
}