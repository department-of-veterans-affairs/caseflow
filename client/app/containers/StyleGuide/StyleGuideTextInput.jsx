import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import TextField from '../../components/TextField';

export default class StyleGuideTextInput extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      value: ''
    };
  }

  render() {
    return <div>
      <StyleGuideComponentTitle
        title="Text Input"
        id="text-input"
        link="StyleGuideTextInput.jsx"
        isSubsection
      />
      <p>A text input field in a form that allows the user to enter requested information.
      It can appear as a field for a single line of text or an area for multiple
      lines of text. For multiple lines of text we can also include a character
      limit description below the text area.</p>
      <p>Text inputs appear in 3 different formats depending on the status of the
      user's input:</p>
      <ul>
        <li>Text Input label (no highlight) indicates that no action has been taken
        in the text field</li>
        <li>Text Input Focused (light blue-gray highlight) indicates that the user
        has selected the input field</li>
        <li>Text Input Error (red highlight) indicates that the user has made an
        error when entering their text</li>
      </ul>
      <TextField
        name="Text Input Label"
        value={this.state.value}
        required={false}
        onChange={(value) => {
          this.setState({ value });
        }} />
      <h3 id="disabled">Disabled Text Input</h3>
      <TextField
        name="Disabled Text Input Label"
        value={""}
        readOnly
        required={false} />
    </div>;
  }
}
