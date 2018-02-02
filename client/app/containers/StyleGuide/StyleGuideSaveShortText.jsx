import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import EditableField from '../../components/EditableField';

export default class StyleGuideSaveShortText extends React.PureComponent {
  constructor() {
    super();

    this.state = {
      value: ''
    };
  }

  isEmpty = (str) => {
    return (!str || str.length === 0);
  }

  onChange = (event) => {
    this.setState({
      value: event
    });
  }

  render() {
    return <div>
      <StyleGuideComponentTitle
        title="Save short text"
        id="save-short-text"
        link="StyleGuideSaveShortText.jsx"
        isSubsection
      />
      <EditableField
        value={this.state.value}
        onSave={() => console.log("placeholder for save")}
        onChange={this.onChange}
        onCancel={() => console.log("placeholder for cancel")}
        maxLength={50}
        label="Document title"
        strongLabel
        name="document_title"
        errorMessage={this.isEmpty(this.state.value) ? "Please enter some text" : null}
      />
    </div>
  }
}
