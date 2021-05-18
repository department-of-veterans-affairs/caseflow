import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';
import _ from 'lodash';

export default class Button extends React.Component {
  componentDidMount() {
    if (this.props.type === 'submit') {
      console.warn(`Warning! You are using a button with type submit.
        Was this intended? Make sure to use event.preventDefault() if
        you're using it with a form and an onClick handler`);
    }
  }

  render() {
    let propClassNames = this.props.classNames;
    let {
      ariaLabel,
      app,
      loadingText,
      children,
      id,
      name,
      disabled,
      loading,
      onClick,
      linkStyling,
      dangerStyling,
      redStyling,
      willNeverBeLoading,
      type,
      styling,
      title,
      role
    } = this.props;

    let LoadingIndicator = () => {
      app = app || 'default';

      children = loadingText || 'Loading...';

      return (
        <span>
          <button
            id={`${id || `${type}-${name.replace(/\s/g, '-')}`}-loading`}
            className={`${propClassNames.join(' ')} cf-${app} cf-loading`}
            type={type}
            disabled
            aria-label={ariaLabel}
          >
            <span className="cf-loading-icon-container">
              <span className="cf-loading-icon-front">
                <span className="cf-loading-icon-back">{children}</span>
              </span>
            </span>
          </button>
        </span>
      );
    };

    children = children || name;

    if (disabled || loading) {
      // remove any usa-button styling and then add disabled styling
      propClassNames = propClassNames.filter((className) => !className.includes('usa-button'));
      propClassNames.push('usa-button-disabled');
    }

    const buttonClasses = classnames(propClassNames, {
      'hidden-field': loading,
      'cf-btn-link': linkStyling,
      'usa-button-secondary': dangerStyling,
      'usa-button': !dangerStyling,
      'usa-button-red': redStyling
    });

    const button = (
      <button
        id={id || (name && `${type}-${name.replace(/\s/g, '-')}`)}
        className={buttonClasses}
        type={type}
        disabled={disabled}
        onClick={onClick}
        title={title}
        aria-label={ariaLabel}
        role={role}
        {...styling}
      >
        {children}
      </button>
    );

    /**
     * If we having a loading indicator, then we'll wrap the <button> in a <span>.
     * This breaks the built-in USWDS styling, which assumes that if a button is the
     * last child, then it should be styled differently. When we wrap every button
     * in a span, every button is a last child.
     *
     * Button is used all over our codebase, and some places may rely on this behavior.
     * So instead of changing it for everyone, we'll allow users to opt in with the
     * willNeverBeLoading prop. This will produce the styling that USWDS intended.
     */
    if (willNeverBeLoading) {
      return button;
    }

    return (
      <span>
        {button}
        {loading && <LoadingIndicator />}
      </span>
    );
  }
}

Button.defaultProps = {
  classNames: ['cf-submit'],
  type: 'button',
  loading: false,
  willNeverBeLoading: false,
  linkStyling: false
};

Button.propTypes = {
  app: PropTypes.string,
  ariaLabel: PropTypes.string,
  children: PropTypes.node,
  classNames: PropTypes.arrayOf(PropTypes.string),
  disabled: PropTypes.bool,
  dangerStyling: PropTypes.bool,
  id: PropTypes.string,

  /**
   * Styles the button like a link when true
   */
  linkStyling: PropTypes.bool,

  /**
   * Boolean that disables button and shows a loading indicator
   */
  loading: (props, propName) => {
    const loading = props[propName];

    if (_.isUndefined(loading)) {
      return;
    }

    if (!_.isBoolean(loading)) {
      return new Error(`'loading' must be a boolean, but was: '${loading}'`);
    }

    if (loading && props.willNeverBeLoading) {
      return new Error("'loading' and 'willNeverBeLoading' can't both be set to 'true'.");
    }
  },
  loadingText: PropTypes.string,
  willNeverBeLoading: PropTypes.bool,
  name: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
  onClick: PropTypes.func,
  redStyling: PropTypes.bool,

  /**
   * Accepts an object that is spread out as props on `button` element
   */
  styling: PropTypes.object,
  title: PropTypes.string,
  type: PropTypes.oneOf(['button', 'submit', 'reset']),
  role: PropTypes.string
};
