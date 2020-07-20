import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

const labelTextStyling = css({
  marginTop: '0.65em',
  marginBottom: '0.65em'
});

export default class TextField extends React.Component {

  onChange = (event) => this.props.onChange(event.target.value);

  render() {

    let {
      errorMessage,
      className,
      label,
      name,
      readOnly,
      required,
      optional,
      type,
      value,
      validationError,
      invisible,
      placeholder,
      title,
      onKeyPress,
      strongLabel,
      maxLength,
      max,
      autoComplete,
      useAriaLabel,
      dateErrorMessage,
      labelText,
      inputStyling
    } = this.props;

    let textInputClass = className.concat(
      invisible ? ' cf-invisible' : ''
    ).concat(
      errorMessage ? 'usa-input-error' : ''
    ).
      concat(
        dateErrorMessage ? 'cf-date-error' : ''
      );

    // Use empty string instead of null or undefined,
    // otherwise React displays the following error:
    //
    // "`value` prop on `input` should not be null.
    // Consider using the empty string to clear the component
    // or `undefined` for uncontrolled components."
    //
    value = (value === null || typeof value === 'undefined') ? '' : value;

    const labelContents =
      <span>
        {label || name}
        {required && !readOnly && <span className="cf-required">Required</span>}
        {optional && <span className="cf-optional">Optional</span>}
      </span>;

    const ariaLabelObj = useAriaLabel ? { 'aria-label': name } : {};

    return <div className={textInputClass.join(' ')}>
      {dateErrorMessage && <span className="usa-input-error-message">{dateErrorMessage}</span>}
      {label !== false &&
        <label htmlFor={name}>
          {
            strongLabel ?
              <strong>{labelContents}</strong> :
              labelContents
          }
        </label>
      }
      {labelText && <p{...labelTextStyling}>{labelText}</p>}
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      {this.props.fixedInput ?
        <p>{value}</p> :
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
          max={max}
          autoComplete={autoComplete}
          {...ariaLabelObj}
          {...inputStyling}
        />
      }

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
  optional: false,
  useAriaLabel: false,
  type: 'text',
  className: ['cf-form-textinput']
};

TextField.propTypes = {
  dateErrorMessage: PropTypes.string,
  errorMessage: PropTypes.string,
  className: PropTypes.arrayOf(PropTypes.string),
  invisible: PropTypes.bool,
  label: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.bool
  ]),
  labelText: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.bool
  ]),
  useAriaLabel: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onChange(props) {
    if (!props.readOnly) {
      if (typeof props.onChange !== 'function') {
        return new Error('If TextField is not ReadOnly, then onChange must be defined');
      }
    }
  },
  title: PropTypes.string,
  onKeyPress: PropTypes.func,
  strongLabel: PropTypes.bool,
  maxLength: PropTypes.number,
  max: PropTypes.any,
  autoComplete: PropTypes.string,
  placeholder: PropTypes.string,
  readOnly: PropTypes.bool,
  fixedInput: PropTypes.bool,
  required: PropTypes.bool.isRequired,
  optional: PropTypes.bool.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number
  ]),
  inputStyling: PropTypes.object
};
