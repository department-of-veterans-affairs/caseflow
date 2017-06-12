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

    <h3>Primary Buttons</h3>
    <div className="usa-grid">
     <div className="usa-width-one-third">
     <h3 className="styleguide-grey-header">Default</h3>
        <Button
          name="signup-1"
          classNames={['button_wrapper']}>
          Sign up
        </Button><br/><br/>
        <Button
          name="signup-2"
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
          name="signup-4"
          classNames={['usa-button-secondary usa-button-hover']}>
          Sign up
        </Button>
     </div>
    <div className="usa-width-one-third">
    <h3 className="styleguide-grey-header">Active</h3>
        <Button
          name="signup-5"
          classNames={['usa-button-active']}>
          Sign up
        </Button><br/><br/>
        <Button
          name="signup-6"
          classNames={['usa-button-secondary usa-button-active']}>
          Sign up
        </Button>
     </div>
    </div><br/><br/>
    <h3>Secondary Buttons</h3>
    <div className="usa-grid">
    <div className="usa-width-one-third">
    <h3 className="styleguide-grey-header">Default</h3>
        <Button
          name="signup-7"
          classNames={['usa-button-outline']}>
          Sign up
        </Button>
    </div>
    <div className="usa-width-one-third">
    <h3 className="styleguide-grey-header">Hover</h3>
        <Button
          name="signup-8"
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
    </div>
    <StyleGuideLinkButton />
    </div>;
 }
}