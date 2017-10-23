import React from 'react';
import Button from '../../components/Button';
import StyleGuideLinkButton from './StyleGuideLinkButton';
import StyleGuideToggleButton from './StyleGuideToggleButton';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideButton extends React.Component {
  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Buttons"
        id="buttons"
        link="StyleGuideButton.jsx"
      />
      <p>
     Primary actions are visually prioritized by being solid blue <code>usa-button</code> style.
      </p>

      <p>
     Finally, there are actions that we generally want to discourage but should remain visible
     to users as an escape hatch.
      </p>

      <p>
     These actions can be <code>button-link</code> styles or use the <code>usa-button-secondary style</code>.
     For example, the “Cancel” button frequently found at the bottom of Caseflow workflow layouts
     is usually a button link because it launches a modal.
     The button to confirm that a user wants to cancel is red and serves as a warning to the user
     that the action is destructive. These styles should be used sparingly.</p>

      <p>
      The width of the button will vary depending on the length of the content.
      In the source code, the buttons are set so that there is always 20px padding on the left
      and right of the text. While it is ideal not to change the default setting, in a case where
      buttons of various widths are stacked, we highly recommend adjusting the padding of the buttons
      so that they all match in width.</p>

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
      <StyleGuideToggleButton />
    </div>;
  }
}
