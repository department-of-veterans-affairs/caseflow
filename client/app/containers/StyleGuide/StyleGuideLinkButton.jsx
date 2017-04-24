import React from 'react';
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

let StyleGuideLinkButton = () => {
  return <div>
    <br/>
    <StyleGuideComponentTitle
      title="Link buttons"
      id="link_buttons"
      link="StyleGuideLinkButton.jsx"
      subsection={true}
    />
    <div className="usa-grid">
      <div className="usa-width-one-third">
        <h3 className="styleguide-grey-header">Default</h3>
        <Button
          name="signup-1"
          classNames={['usa-button-outline']}>
          Signup
        </Button><br/><br/>
        <Button
          name="signup-2"
          classNames={['cf-btn-link']}>
          Signup
        </Button>
      </div>
      <div className="usa-width-one-third">
        <h3 className="styleguide-grey-header">Hover</h3>
        <Button
          name="signup-3"
          classNames={['usa-button-outline usa-button-hover']}>
          Signup
        </Button><br/><br/>
        <Button
          name="signup-4"
          classNames={['cf-btn-link button-hover']}>
          Signup
        </Button>
      </div>
      <div className="usa-width-one-third">
        <h3 className="styleguide-grey-header">Active</h3>
        <Button
          name="signup-5"
          classNames={['usa-button-outline usa-button-active']}>
          Signup
        </Button><br/><br/>
        <Button
          name="signup-6"
          classNames={['cf-btn-link button-active']}>
          Signup
        </Button>
      </div>
    </div>
    <br/>
  </div>;
};

export default StyleGuideLinkButton;
