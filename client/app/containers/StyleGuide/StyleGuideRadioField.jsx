import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

import Example1 from './RadioFieldExamples/Example1';
import Example2 from './RadioFieldExamples/Example2';
import Example3 from './RadioFieldExamples/Example3';
import Example4 from './RadioFieldExamples/Example4';

export default class StyleGuideRadioField extends React.Component {

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Radio Buttons"
        id="radios"
        link="StyleGuideRadioField.jsx"
      />
      <p>largely follow the same design as those in the US Web Design Standards
        but we also include horizontal radio buttons. This layout is used when
        there are at most 2 options.</p>
      <h3>Vertical Radio Button</h3>
      <Example1 />
      <h3>Horizontal Radio Button</h3>
      <Example2 />
      <h3>Horizontal Radio Button Forced Into Vertical Layout</h3>
      <Example3 />
      <h3>Required Radio Button Errors</h3>
      <Example4 />
    </div>;
  }
}
