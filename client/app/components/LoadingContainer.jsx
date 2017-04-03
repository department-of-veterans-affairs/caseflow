import React, { PropTypes } from 'react';
import { loadingSymbolHtml } from './RenderFunctions.jsx';
export default class LoadingContainer extends React.Component {
  render() {
    return <div className="loadingContainer-container">
        <div className="loadingContainer-positioning">
          <div className="loadingContainer-table">
            <div className="loadingContainer-table-cell">
              {loadingSymbolHtml('', '300', '#844E9F')}
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
  children: PropTypes.node
};
