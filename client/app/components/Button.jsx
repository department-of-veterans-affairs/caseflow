import React, { PropTypes } from 'react';
import { loadingSymbolHtml } from './RenderFunctions.jsx';

export default class Button extends React.Component {
  render() {
    let {
      classNames,
      name,
      disabled,
      loading,
      onClick,
      type
    } = this.props;

    return <span>
    {loading && loadingSymbolHtml()}
    {!loading &&
      <button
        id={`${type}_${name.replace(/\s/g, '_')}`}
        className={classNames ? classNames.join(' ') : "cf-submit"}
        type={type}
        disabled={disabled}
        onClick={onClick}>
          {name}
      </button>
    }
    </span>;
  }
}

Button.defaultProps = {
  type: 'button'
};

Button.propTypes = {
  disabled: PropTypes.bool,
  linkStyle: PropTypes.bool,
  loading: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onClick: PropTypes.func,
  type: PropTypes.string
};
