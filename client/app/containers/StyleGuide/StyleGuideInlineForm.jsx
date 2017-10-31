import React from 'react';

// components
import NumberField from '../../components/NumberField';
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import InlineForm from '../../components/InlineForm';

export default class StyleGuideInlineForm extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      value: null
    };
  }

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Inline Form"
        id="inline_form"
        link="StyleGuideInlineForm.jsx"
        isSubsection
      />
      <p>
        Inline forms give designers and developers the liberty to customize
        the width and spacing of each field in a row. Input fields can be found
        placed after labels and descriptions to provide users context and
        actionable steps.
      </p>
      <InlineForm>
        <NumberField
          label="Enter the number of people working today"
          name="dummyEmployeeCount"
          isInteger
          value={this.state.value}
          onChange={(value) => {
            this.setState({ value });
          }}
        />
        <Button
          name="Update"
        />
      </InlineForm>
    </div>;
  }
}
