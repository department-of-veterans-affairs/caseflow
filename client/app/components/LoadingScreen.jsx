import React from 'react';
import { LoadingSymbol } from './RenderFunctions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';
import PropTypes from 'prop-types';

const centerTextStyling = css({
  textAlign: 'center',
  height: '300px',
  marginTop: '75px'
});

const LoadingScreen = (props) =>
  <AppSegment filledBackground>
    <div {...centerTextStyling}>
      <LoadingSymbol
        text=""
        size="150px"
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
