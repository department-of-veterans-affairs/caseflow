import React from 'react';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StyleGuideInlineForm from './StyleGuideInlineForm';
import StyleGuideTextInput from './StyleGuideTextInput';

let StyleGuideFormFields = () => {

  return (
    <div>
      <h2 id="form_fields">Form Fields</h2>
      <StyleGuideTextInput/>
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
