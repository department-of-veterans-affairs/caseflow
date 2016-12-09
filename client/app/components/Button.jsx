import React, { PropTypes } from 'react';
import { loadingSymbolHtml } from './RenderFunctions.jsx';

export default class Button extends React.Component {
  render() {
    let {
      name,
      disabled,
      loading,
      onClick,
      type,
      linkStyle
    } = this.props;

    return <span>
    {loading && loadingSymbolHtml()}
    {!loading &&
      <button
        type={type}
        className={"cf-submit" + (linkStyle ? " cf-btn-link" : "")}
        disabled={disabled}
        onClick={onClick}>
          {name}
      </button>
    }
    </span>;
  }
}

Button.defaultProps = {
  type: 'button',
  linkStyle: false
};

Button.propTypes = {
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onClick: PropTypes.func,
  type: PropTypes.string,
  linkStyle: PropTypes.bool
};
