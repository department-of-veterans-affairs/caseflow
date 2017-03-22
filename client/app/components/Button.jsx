import React, { PropTypes } from 'react';

export default class Button extends React.Component {
  componentDidMount() {
    if (this.props.type === 'submit') {
      console.warn(`Warning! You are using a button with type submit.
        Was this intended? Make sure to use event.preventDefault() if
        you're using it with a form and an onClick handler`);
    }
  }

  loadingClasses = (app, loading) => {
    let classes = ` cf-${app}`;

    if (loading) {
      classes += " cf-loading";
    }

    return classes;
  }

  render() {
    let {
      app,
      loadingText,
      classNames,
      children,
      id,
      name,
      disabled,
      loading,
      onClick,
      type
    } = this.props;

    let LoadingIndicator = () => {
      if (!app) {
        app = 'dispatch';
      }
      children = loadingText || "Loading...";

      return <span>
        <button
          id={`${id || `${type}-${name.replace(/\s/g, '-')}`}-loading`}
          className={classNames.join(' ') + this.loadingClasses(app, loading)}
          type={type}
          disabled={true}>
          <span className="cf-loading-icon-container">
            <span className="cf-loading-icon-front">
              <span className="cf-loading-icon-back">
                {children}
              </span>
            </span>
          </span>
        </button>
      </span>;
    };

    if (!children) {
      children = name;
    }

    if (disabled || loading) {
      // remove any usa-button styling and then add disabled styling
      classNames = classNames.filter((className) => !className.includes('usa-button'));
      classNames.push('usa-button-disabled');
    }

    return <span>
      <button
        id={id || `${type}-${name.replace(/\s/g, '-')}`}
        className={classNames.join(' ') + (loading ? " hidden-field" : "")}
        type={type}
        disabled={disabled}
        onClick={onClick}>
          {children}
      </button>

      { loading && <LoadingIndicator /> }
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
