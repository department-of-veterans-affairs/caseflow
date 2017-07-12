import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import LoadingContainer from '../../components/LoadingContainer';
import * as AppConstants from '../../constants/AppConstants';

export default class StyleGuideLoaders extends React.Component {

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Loaders"
        id="loaders"
        link="StyleGuideLoaders.jsx"
      />
     <p>
       A large Caseflow loading indicator in the center of the page is used
       when some information has been retrieved but other information is still being pulled.
       Each loader should have a message underneath the logo in <code>gray-dark</code> that explains
       what is currently happening or where the information is being drawn from. </p>


     <div className="cf-sg-loader">
      <LoadingContainer color={AppConstants.LOADING_INDICATOR_COLOR_DISPATCH}>
        <div className="cf-image-loader">
        </div>
        <p className="cf-txt-c"> Gathering information in VBMS now......</p>
      </LoadingContainer>
     </div>

    </div>;
  }
}
