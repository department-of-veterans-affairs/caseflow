import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import Example1 from './CheckboxExamples/Example1';
import Example2 from './CheckboxExamples/Example2';
import Example3 from './CheckboxExamples/Example3';
import Example4 from './CheckboxExamples/Example4';
import Example5 from './CheckboxExamples/Example5';
import Example6 from './CheckboxExamples/Example6';
import Example7 from './CheckboxExamples/Example7';

export default class StyleGuideCheckboxes extends React.Component {
  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Checkboxes"
        id="checkboxes"
        link="StyleGuideCheckboxes.jsx"
      />
      <p>Checkboxes largely follow the same design as those in the
        US Web Design Standards but we also include horizontal checkboxes.
        Checkboxes allow an alternative way to selection key responses
        through out Caseflow Applications. This layout is used when there
        are at most 2 options.</p>
      <h3>Single Checkbox</h3>
      <Example1 />
      <h3>Single Checkbox with value set</h3>
      <Example2 />
      <h3>Vertical Checkboxes</h3>
      <Example3 />
      <h3>Horizontal Checkboxes</h3>
      <Example4 />
      <h3>Forced Vertical Checkboxes</h3>
      <Example5 />
      <h3>Required Checkboxes</h3>
      <Example6 />
      <h3>Acknowledgements</h3>
      <p>In certain circumstances we ask the user to click a checkbox agreeing
        to an action before proceeding. The text here should be limited to 75
        characters and indented so it doesn't flow under the checkbox.  Most of
        the time these checkboxes should have a required indicator and send an
        error state if a user tries to proceed without making a selection.</p>
      <Example7 />
    </div>;
  }
}
