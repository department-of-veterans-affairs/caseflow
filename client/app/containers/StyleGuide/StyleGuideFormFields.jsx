import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StyleGuideInlineForm from './StyleGuideInlineForm';

let StyleGuideFormFields = () => {

  return (
    <div>
      <h2 id="form_fields">Form Fields</h2>
      <StyleGuidePlaceholder
        title="Text Input"
        id="text_input"
        isSubsection={true} />
      <StyleGuidePlaceholder
        title="Text Input Error"
        id="text_input_error"
        isSubsection={true} />
      <StyleGuidePlaceholder
        title="Text Area"
        id="text_area"
        isSubsection={true} />
      <StyleGuidePlaceholder
        title="Character Limit"
        id="character_limit"
        isSubsection={true} />
      <StyleGuideInlineForm />
  </div>

  );
};

export default StyleGuideFormFields;
