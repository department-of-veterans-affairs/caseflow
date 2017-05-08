import React from 'react';

// components
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import TextStyles from './Typography/TextStyles';

export default class StyleGuideTypography extends React.Component {

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Typography"
        id="typography"
      />
      <TextStyles />
    </div>;
  };
}
