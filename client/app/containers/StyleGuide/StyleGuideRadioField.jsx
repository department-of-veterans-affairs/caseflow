import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

import Example1 from './RadioFieldExamples/Example1';
import Example2 from './RadioFieldExamples/Example2';
import Example3 from './RadioFieldExamples/Example3';
import Example4 from './RadioFieldExamples/Example4';
import Example5 from './RadioFieldExamples/Example5';
import Example6 from './RadioFieldExamples/Example6';

export default class StyleGuideRadioField extends React.Component {

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Radio Buttons"
        id="radios"
        link="StyleGuideRadioField.jsx"
      />
      <p>Radio Buttons are used for selecting one of several choices.</p>
      <Example1 />
      <Example2 />
      <p>
        The component will automatically render two options
        horizontally unless the <strong>vertical</strong> property
        is <strong>true</strong>:
      </p>
      <Example3 />
      <Example4 />
      <Example5 />
      <p>This field hides its label:</p>
      <Example6 />
    </div>;
  }
}
