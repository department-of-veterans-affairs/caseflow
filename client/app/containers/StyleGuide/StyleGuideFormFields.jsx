import React from 'react';
import StyleGuidePlaceholder from './StyleGuidePlaceholder';
import StyleGuideInlineForm from './StyleGuideInlineForm';
import StyleGuideTextInput from './StyleGuideTextInput';
import StyleGuideTextInputError from './StyleGuideTextInputError';
import StyleGuideTextArea from './StyleGuideTextArea';

let StyleGuideFormFields = () => {

  return (
    <div>
      <h2 id="form_fields">Form Fields</h2>
      <StyleGuideTextInput/>
      <StyleGuideTextInputError/>
      <StyleGuideTextArea />
      <StyleGuidePlaceholder
        title="Character Limit"
        id="character_limit"
        isSubsection={true} />
      <StyleGuideInlineForm />
  </div>

  );
};

export default StyleGuideFormFields;
