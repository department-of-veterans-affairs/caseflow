import React from 'react';
import PropTypes from 'prop-types';

import { loadingSymbolHtml } from './RenderFunctions.jsx';
export default class LoadingContainer extends React.Component {
  render() {
    let {
      color
    } = this.props;

    return <div className="loadingContainer-container">
        <div className="loadingContainer-positioning">
          <div className="loadingContainer-table">
            <div className="loadingContainer-table-cell">
              {loadingSymbolHtml('', '50%', color)}
            </div>
          </div>
        </div>
        <div className="loadingContainer-content">
          <div>
            {this.props.children}
          </div>
        </div>
      </div>;
  }
}

LoadingContainer.propTypes = {
  children: PropTypes.node,
  color: PropTypes.string
};
