import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import SaveCommentTextArea from '../../components/SaveCommentTextArea';

export default class StyleGuideSaveLongText extends React.PureComponent {
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
      value: event.target.value
    });
  }

  render() {
    return <div>
      <StyleGuideComponentTitle
        title="Save long text"
        id="save-long-text"
        link="StyleGuideSaveLongText.jsx"
        isSubsection
      />
      <SaveCommentTextArea
        name="Edit Comment"
        disabled={this.isEmpty(this.state.value)}
        onChange={this.onChange}
        value={this.state.value}
      />
    </div>;
  }
}
