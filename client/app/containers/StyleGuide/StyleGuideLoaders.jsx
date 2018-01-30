import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import LoadingContainer from '../../components/LoadingContainer';
import { LOGO_COLORS } from '../../constants/AppConstants';
import StyleGuideSmallLoader from './StyleGuideSmallLoader';
import StyleGuideLoadingButton from './StyleGuideLoadingButton';

export default class StyleGuideLoaders extends React.PureComponent {

  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Loaders"
        id="loaders"
        link="StyleGuideLoaders.jsx"
      />
      <p>
       A large Caseflow loading indicator in the center of the page is used when some
       information has been retrieved but other information is still being pulled.
       Each loader should have a message underneath the logo in <code>gray-dark</code>
       that explains what is currently happening or where the information is being drawn
       from. Loader should match the respective Caseflow app logo. Designers are
       responsible for letting developers know that defaulted color in the source code needs
       to be the color of the app logo.
       See <a href="#colors">Caseflow Logos</a> under the Colors section.</p>

      <div className="cf-sg-loader">
        <LoadingContainer color={LOGO_COLORS.DISPATCH.ACCENT}>
          <div className="cf-image-loader">
          </div>
          <p className="cf-txt-c"> Gathering information in VBMS now......</p>
        </LoadingContainer>
      </div>
      <StyleGuideSmallLoader />
      <StyleGuideLoadingButton />
    </div>;
  }
}
