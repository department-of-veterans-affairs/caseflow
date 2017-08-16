import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import { loadingSymbolHtml } from '../../components/RenderFunctions';

export default class StyleGuideSmallLoader extends React.Component {

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Small Loader"
        id="small_loader"
        link="StyleGuideSmallLoader.jsx"
      />
      <p>
      The small loading indicator can be used when information is still being pulled
      for a specific section on a page. Designers are responsible to indicate what the
      message should say and which application logo to use in the acceptance criteria. </p>

      <div className="cf-sg-loader-font">
      {loadingSymbolHtml('Loading...', '19px', '#417505')}
      </div>
    </div>;

  }
}
