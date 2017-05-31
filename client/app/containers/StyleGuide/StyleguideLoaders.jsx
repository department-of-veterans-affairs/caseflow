import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import LoadingContainer from '../../components/LoadingContainer';

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
       Each loader should have a message underneath the logo in 'gray-dark' that explains
       what is currently happening or where the information is being drawn from. </p>


    <div className = "cf-dispatch-loader">
     <LoadingContainer >
      <div style={{ width: 400, height: 400 }}>
      </div>
      <p className="cf-text-align"> Gathering information in VBMS now......</p>
     </LoadingContainer>
    </div>

    </div>;
  }
}
