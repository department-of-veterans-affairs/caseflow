import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import TextareaField from '../../components/TextareaField';

export default class StyleGuideTextArea extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      value: ''
    };
  }

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Text Area"
        id="text_area"
        link="StyleGuideTextArea.jsx"
        isSubsection={true}
      />
      <p>
        A text area allows multiple lines of text so that users can enter detailed
        and descriptive requested information. This freeform field allows users to
        write as much as they need to. When the message is longer than the length
        of the box, a scroll bar will appear on the side.
      </p>
      <TextareaField
        name="Enter your text here"
        value={this.state.value}
        onChange={(value) => {
          this.setState({ value });
        }}
      />
    </div>;
  }
}
