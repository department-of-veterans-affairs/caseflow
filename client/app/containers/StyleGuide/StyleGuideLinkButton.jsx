import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

let StyleGuideLinkButton = () => {
  return <div>
    <br/>
    <StyleGuideComponentTitle
      title="Link buttons"
      id="link_buttons"
      link="StyleGuideLinkButton.jsx"
    />
    <div className="usa-grid">
      <div className="usa-width-one-third">
        <h3 className="styleguide-grey-header">Default</h3>
        <button className="usa-button-outline">Signup</button><br/>
        <button className="cf-btn-link">Signup</button>
      </div>
      <div className="usa-width-one-third">
        <h3 className="styleguide-grey-header">Hover</h3>
        <button className="usa-button-outline usa-button-hover">Signup</button><br/>
        <button className="cf-btn-link button-hover">Signup</button>
      </div>
      <div className="usa-width-one-third">
        <h3 className="styleguide-grey-header">Active</h3>
        <button className="usa-button-outline usa-button-active">Signup</button><br/>
        <button className="cf-btn-link button-active">Signup</button>
      </div>
    </div>
    <br/>
  </div>;
};

export default StyleGuideLinkButton;
