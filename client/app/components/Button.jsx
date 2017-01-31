import React, { PropTypes } from 'react';
import { loadingSymbolHtml } from './RenderFunctions.jsx';

export default class Button extends React.Component {
  componentDidMount() {
    if (this.props.type === 'submit') {
      console.warn(`Warning! You are using a button with type submit.
        Was this intended? Make sure to use event.preventDefault() if
        you're using it with a form and an onClick handler`);
    }
  }

  render() {
    let {
      classNames,
      children,
      id,
      name,
      disabled,
      loading,
      onClick
    } = this.props;

    if (!children) {
      children = name;
    }

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
        id={id || `button-${name.replace(/\s/g, '-')}`}
        className={classNames.join(' ')}
        type="button"
        disabled={disabled}
        onClick={onClick}>
          {children}
      </button>
    }
    </span>;
  }
}

Button.propTypes = {
  children: PropTypes.node,
  classNames: PropTypes.arrayOf(PropTypes.string),
  disabled: PropTypes.bool,
  id: PropTypes.string,
  linkStyle: PropTypes.bool,
  loading: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onClick: PropTypes.func,
  type: PropTypes.string
};
