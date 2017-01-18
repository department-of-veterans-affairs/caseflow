import React, { PropTypes } from 'react';
import { loadingSymbolHtml } from './RenderFunctions.jsx';

export default class Button extends React.Component {
  render() {
    let {
      classNames,
      id,
      name,
      disabled,
      loading,
      onClick,
      type
    } = this.props;

    if (!classNames) {
      classNames = ['cf-submit'];
    }

    if (disabled) {
      classNames.push('usa-button-disabled');
    }

    return <span>
    {loading && loadingSymbolHtml()}
    {!loading &&
      <button
        id={id || `${type}-${name.replace(/\s/g, '-')}`}
        className={classNames.join(' ')}
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
  classNames: PropTypes.arrayOf(PropTypes.string),
  disabled: PropTypes.bool,
  id: PropTypes.string,
  linkStyle: PropTypes.bool,
  loading: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onClick: PropTypes.func,
  type: PropTypes.string
};
