import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import TextareaField from '../../components/TextareaField';

export default class StyleGuideCharacterLimit extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      value: ''
    };
  }

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Character Limit"
        id="character_limit"
        link="StyleGuideCharacterLimit.jsx"
        isSubsection={true}
      />
      <p>
        Character limits alert users of the maximum possible text input and is used
        to limit the amount of information a user can provide. This friction helps
        ensure the user is providing the appropriate information for the text input.
        As the user types inside the text area, the character number decreases while
        showing the number of characters remaining. When there are 0 characters remaining,
        the text box does not allow for more characters to be inserted.
      </p>
      <TextareaField
        name="Enter your text here (with character limit)"
        value={this.state.value}
        onChange={(value) => {
          this.setState({ value });
        }}
        maxlength={2000}
      />
    </div>;
  }
}
