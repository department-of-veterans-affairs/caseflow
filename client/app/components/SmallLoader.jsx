import React from 'react';
import { loadingSymbolHtml } from './RenderFunctions';
import PropTypes from 'prop-types';

export default class SmallLoader extends React.Component {

  render() {
    const {
      message,
      spinnerColor
    } = this.props;

    return <div
      id="small-loader"
      className="cf-small-loader">
      {loadingSymbolHtml(message, '19px', spinnerColor)}
    </div>;
  }
}

SmallLoader.propTypes = {
  message: PropTypes.string.isRequired,
  spinnerColor: PropTypes.string.isRequired
};

