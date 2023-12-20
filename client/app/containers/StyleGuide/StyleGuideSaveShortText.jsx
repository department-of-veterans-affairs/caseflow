import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import EditableField from '../../components/EditableField';

export default class StyleGuideSaveShortText extends React.PureComponent {
  constructor() {
    super();

    this.state = {
      currentValue: '',
      value: ''
    };
  }

  onChange = (event) => {
    this.setState({
      value: event
    });
  }

  onCancel = () => {
    this.setState({
      value: this.state.currentValue
    });
  }

  onSave = (event) => {
    this.setState({
      currentValue: event
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
        onSave={this.onSave}
        onChange={this.onChange}
        onCancel={this.onCancel}
        maxLength={50}
        label="Document title"
        strongLabel
        name="document_title"
      />
    </div>;
  }
}
