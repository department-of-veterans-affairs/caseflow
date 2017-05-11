import React from 'react';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StyleGuideInlineForm from './StyleGuideInlineForm';
import StyleGuideTextArea from './StyleGuideTextArea';
import StyleGuideCharacterLimit from './StyleGuideCharacterLimit';

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
      <StyleGuideTextArea />
      <StyleGuideCharacterLimit />
      <StyleGuideInlineForm />
  </div>

  );
};

export default StyleGuideFormFields;
