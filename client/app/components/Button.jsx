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
      onClick,
      type
    } = this.props;
    // Disabled the button when loading

    if (!children) {
      children = name;
    }

    if (loading) {
      disabled = loading;
      children = loadingSymbolHtml();
    }

    if (disabled) {
      // remove any usa-button styling and then add disabled styling
      classNames = classNames.filter((className) => !className.includes('usa-button'));
      classNames.push('usa-button-disabled');
    }

    return <span>
      <button
        id={id || `${type}-${name.replace(/\s/g, '-')}`}
        className={classNames.join(' ')}
        type={type}
        disabled={disabled}
        onClick={onClick}>
          {children}
      </button>
    </span>;
  }
}

Button.defaultProps = {
  classNames: ['cf-submit'],
  type: 'button'
};

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
