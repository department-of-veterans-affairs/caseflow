import React from 'react';
import { LoadingIcon } from './icons/LoadingIcon';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';

const centerTextStyling = {
  textAlign: 'center',
  height: '300px',
  marginTop: '75px'
};

const LoadingScreen = (props) =>
  <AppSegment filledBackground>
    <div style={centerTextStyling}>
      <LoadingIcon
        text=""
        size={150}
        color={props.spinnerColor}
      />
      <p>{props.message}</p>
    </div>
  </AppSegment>;

LoadingScreen.propTypes = {
  spinnerColor: PropTypes.string,
  message: PropTypes.string
};

export default LoadingScreen;
