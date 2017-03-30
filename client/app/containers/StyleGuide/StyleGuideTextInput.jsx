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
    <h3>Inline Form</h3>
      <p>
        Inline forms give designers and developers the liberty to customize
        the width and spacing of each field in a row. Input fields can be found
        placed after labels and descriptions to provide users context and actionable steps.
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
