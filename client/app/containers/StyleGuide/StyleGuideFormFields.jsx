import React from 'react';
import StyleGuideInlineForm from './StyleGuideInlineForm';
import StyleGuideTextInput from './StyleGuideTextInput';
import StyleGuideTextInputError from './StyleGuideTextInputError';
import StyleGuideTextArea from './StyleGuideTextArea';
import StyleGuideCharacterLimit from './StyleGuideCharacterLimit';
import StyleGuideSaveLongText from './StyleGuideSaveLongText';
import StyleGuideSaveShortText from './StyleGuideSaveShortText';

export default class StyleGuideFormFields extends React.PureComponent {
  render = () => {

    return <div>
      <h2 id="form-fields">Form Fields</h2>
      <StyleGuideTextInput />
      <StyleGuideTextInputError />
      <StyleGuideTextArea />
      <StyleGuideCharacterLimit />
      <StyleGuideInlineForm />
      <StyleGuideSaveLongText />
      <StyleGuideSaveShortText />
    </div>;
  }
}
