import React from 'react';

// components
import StyleGuideComponentTitle from '../../../components/StyleGuideComponentTitle';

export default class FontFamily extends React.Component {

  render = () => {
    return <div className="cf-sg-font-family-examples">
      <StyleGuideComponentTitle
        title="Font Family"
        id="font-family"
        isSubsection
      />
      <p className="cf-font-light">Source Sans Pro Light (300)</p>
      <p>Source Sans Pro Regular (400)</p>
      <p><i>Source Sans Pro Italic (400)</i></p>
      <p><b>Source Sans Pro Bold (400)</b></p>
    </div>;
  };
}
