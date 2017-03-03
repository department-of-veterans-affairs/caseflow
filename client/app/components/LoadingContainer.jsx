import React, { PropTypes } from 'react';
import { loadingSymbolHtml } from './RenderFunctions.jsx'
export default class LoadingContainer extends React.Component {
  render() {
    let {
      label,
      name,
      value
    } = this.props;

    return <div className="react-loading-container-container">
        <div className="react-loading-container-positioning">
          <div className="react-loading-container-table">
            <div className="react-loading-container-table-cell">
              {loadingSymbolHtml('', '50%')}
            </div>
          </div>
        </div>
        <div className="react-loading-container-content">
          {this.props.children}
        </div>
      </div>;
  }
}

LoadingContainer.propTypes = {
  children: PropTypes.node
};

