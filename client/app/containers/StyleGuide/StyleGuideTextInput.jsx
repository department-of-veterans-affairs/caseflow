import React from 'react';

// components
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import InlineField from '../../components/InlineField';

export default function StyleGuideTextInput() {
  return <div>
      <br />
      <StyleGuideComponentTitle
        title="Text Input"
        id="text_input"
        link="StyleGuideTextInput.jsx"
      />
    <h3>Inline Input</h3>
      <p>
        Inline form fields are used for single values only. This field will have
        a label, text input, and a blue CTA button aligned in one row.
      </p>
    <InlineField>
      <TextField
        label="Enter the number of people working today"
        name="dummyEmployeeCount"
        type="number"
      />
      <Button
        name="Update"
      />
    </InlineField>
  </div>;
}
