import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import TextStyles from './Typography/TextStyles';
import FontFamily from './Typography/FontFamily';

export default class StyleGuideTypography extends React.Component {

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Typography"
        id="typography"
      />
      <p>
        The typography of Caseflow is very simple. We use Source Sans Pro as our only font.
        The text styles comes in different weights and sizes to provide visual hierarchy
        and clear context for users. Each text style has a set <code> margin-bottom</code>
        so that there is balance in a page and spacing between applications are consistent.
        The lead paragraph is encouraged to be used for instructions, descriptions and form
        copies. For clarity and readability, the text styles are set to a character width limit.
        On the contrary, the character width is not applicable for Tables and Alerts.
      </p>
      <TextStyles />
      <FontFamily />
    </div>;
  };
}
