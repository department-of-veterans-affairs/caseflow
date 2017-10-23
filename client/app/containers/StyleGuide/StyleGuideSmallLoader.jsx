import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import SmallLoader from '../../components/SmallLoader';
import * as AppConstants from '../../constants/AppConstants';

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

      <SmallLoader
        message="Loading..."
        spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_READER}
      />
    </div>;

  }
}
