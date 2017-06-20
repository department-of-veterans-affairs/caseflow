import React from 'react';
import Button from '../../components/Button';
import StyleGuideLinkButton from './StyleGuideLinkButton';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideButton extends React.Component {
  render = () => {
    return <div>
    <StyleGuideComponentTitle
      title="Buttons"
      id="buttons"
      link="StyleGuideButton.jsx"
    />

    <h3>Primary buttons</h3>
    <div className="usa-grid">
     <div className="usa-width-one-third">
     <h3 className="styleguide-grey-header">Default</h3>
        <Button
          name="signup-1"
          classNames={['button_wrapper']}>
          Sign up
        </Button><br/><br/>
        <Button
          name="signup-button"
          classNames={['usa-button-secondary']}>
          Sign up
        </Button>
        </div>
    <div className="usa-width-one-third">
    <h3 className="styleguide-grey-header">Hover</h3>
        <Button
          name="signup-3"
          classNames={['usa-button-hover']}>
          Sign up
        </Button><br/><br/>
        <Button
          name="signup-hover"
          classNames={['usa-button-secondary usa-button-hover']}>
          Sign up
        </Button>
     </div>
    <div className="usa-width-one-third">
    <h3 className="styleguide-grey-header">Active</h3>
        <Button
          name="signup-active"
          classNames={['usa-button-active']}>
          Sign up
        </Button><br/><br/>
        <Button
          name="signup-secondary"
          classNames={['usa-button-secondary usa-button-active']}>
          Sign up
        </Button>
    </div>
    </div><br/><br/>
    <h3>Secondary buttons</h3>
    <div className="usa-grid">
    <div className="usa-width-one-third">
    <h3 className="styleguide-grey-header">Default</h3>
        <Button
          name="signup-outline"
          classNames={['usa-button-outline']}>
          Sign up
        </Button>
    </div>
    <div className="usa-width-one-third">
    <h3 className="styleguide-grey-header">Hover</h3>
        <Button
          name="signup-"
          classNames={['usa-button-outline usa-button-hover']}>
          Sign up
        </Button>
    </div>
    <div className="usa-width-one-third">
    <h3 className="styleguide-grey-header">Active</h3>
       <Button
         name="signup-9"
         classNames={['usa-button-outline usa-button-active']}>
         Sign up
       </Button>
    </div>
    </div><br/><br/>
    <h3>Disabled button</h3>
    <div className="usa-grid">
    <div className="usa-width-one-third">
       <Button
         name="signup-disabled"
         classNames={['usa-button-disabled']}>
         Sign up
       </Button>
    </div>
    </div>
    <StyleGuideLinkButton />
    </div>;
  }
}
