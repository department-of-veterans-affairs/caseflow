import React from 'react';

// components
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import InlineForm from '../../components/InlineForm';

export default function StyleGuideTextInput() {
  return <div>
      <br />
      <StyleGuideComponentTitle
        title="Text Input"
        id="text_input"
        link="StyleGuideTextInput.jsx"
      />
    <h3>Inline Text Input</h3>
      <p>
        Text input allows users to insert numbers or text into a field.
        The width of the input field will vary according to the context,
        whether it is for a number or name of a state, so that users are primed
        to know what to type in.
      </p>
    <InlineForm>
      <TextField
        label="Enter the number of people working today"
        name="dummyEmployeeCount"
        type="number"
      />
      <Button
        name="Update"
      />
  </InlineForm>
  </div>;
}
