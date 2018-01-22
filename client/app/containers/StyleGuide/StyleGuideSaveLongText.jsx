import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideInlineForm extends React.PureComponent {
  render() {
    return <div>
      <StyleGuideComponentTitle
        title="Save long text"
        id="save-long-text"
        link="StyleGuideSaveLongText.jsx"
        isSubsection
      />
    </div>
  }
}
