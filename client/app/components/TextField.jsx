import React from 'react';
import PropTypes from 'prop-types';

export default class TextField extends React.Component {

  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {

    let {
      errorMessage,
      className,
      label,
      name,
      readOnly,
      required,
      type,
      value,
      validationError,
      invisible,
      placeholder,
      title,
      onKeyPress,
      strongLabel,
      maxLength
    } = this.props;

    let textInputClass = className.concat(
      invisible ? ' cf-invisible' : ''
    ).concat(
      errorMessage ? 'usa-input-error' : ''
    );

    // Use empty string instead of null or undefined,
    // otherwise React displays the following error:
    //
    // "`value` prop on `input` should not be null.
    // Consider using the empty string to clear the component
    // or `undefined` for uncontrolled components."
    //
    value = (value === null || typeof value === 'undefined') ? '' : value;

    const labelContents = <span>{label || name} {required && <span className="cf-required">Required</span>}</span>;

    return <div className={textInputClass.join(' ')}>
      {(label !== false) &&
        <label className="question-label" htmlFor={name}>
          {
            strongLabel ?
              <strong>{labelContents}</strong> :
              labelContents
          }
        </label>
      }
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <input
        className={className}
        name={name}
        id={name}
        onChange={this.onChange}
        onKeyPress={onKeyPress}
        type={type}
        value={value}
        readOnly={readOnly}
        placeholder={placeholder}
        title={title}
        maxLength={maxLength}
      />

      {(validationError) &&
        <div className="cf-validation">
          <span>{validationError}</span>
        </div>
      }
    </div>;
  }
}

TextField.defaultProps = {
  required: false,
  type: 'text',
  className: ['cf-form-textinput']
};

TextField.propTypes = {
  errorMessage: PropTypes.string,
  className: PropTypes.arrayOf(PropTypes.string),
  invisible: PropTypes.bool,
  label: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.bool
  ]),
  name: PropTypes.string.isRequired,
  onChange(props) {
    if (!props.readOnly) {
      if (typeof props.onChange !== 'function') {
        return new Error('If TextField is not ReadOnly, then onChange must be defined');
      }
    }
  },
  placeholder: PropTypes.string,
  readOnly: PropTypes.bool,
  required: PropTypes.bool.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number
  ])
};
