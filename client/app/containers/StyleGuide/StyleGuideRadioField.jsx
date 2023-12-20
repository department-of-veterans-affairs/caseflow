import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

import Example1 from './RadioFieldExamples/Example1';
import Example2 from './RadioFieldExamples/Example2';
import Example3 from './RadioFieldExamples/Example3';
import Example4 from './RadioFieldExamples/Example4';
import Example5 from './RadioFieldExamples/Example5';

export default class StyleGuideRadioField extends React.PureComponent {

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Radio Buttons"
        id="radios"
        link="StyleGuideRadioField.jsx"
      />
      <p>Radio buttons largely follow the same design as those in the
        US Web Design Standards but we also include horizontal radio buttons.
        This layout is used when there are at most 2 options.</p>
      <Example1 />
      <Example2 />
      <Example3 />
      <h3>Required Radio Button</h3>
      <Example4 />
      <Example5 />
    </div>;
  }
}
