import React from 'react';
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideLinkButton extends React.PureComponent {
  render = () => {

    return <div>
      <br />
      <StyleGuideComponentTitle
        title="Link buttons"
        id="link-buttons"
        link="StyleGuideLinkButton.jsx"
        isSubsection
      />
      <div className="usa-grid">
        <div className="usa-width-one-third">
          <h3 className="styleguide-grey-header">Default</h3>
          <Button
            name="signup-2"
            classNames={['cf-btn-link']}>
          Sign up
          </Button>
        </div>
        <div className="usa-width-one-third">
          <h3 className="styleguide-grey-header">Hover</h3>
          <Button
            name="signup-4"
            classNames={['cf-btn-link button-hover']}>
          Sign up
          </Button>
        </div>
        <div className="usa-width-one-third">
          <h3 className="styleguide-grey-header">Active</h3>
          <Button
            name="signup-6"
            classNames={['cf-btn-link button-active']}>
          Sign up
          </Button>
        </div>
      </div>
      <br />
      <h3 id="disabled">Disabled Link button</h3>
      <div className="usa-grid">
        <div className="usa-width-one-third">
          <Button
            name="signup-disabled"
            disabled
            classNames={['cf-btn-link']}>
          Sign up
          </Button>
        </div>
      </div>
      <br />
    </div>;
  }
}

