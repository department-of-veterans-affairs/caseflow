import React, { PropTypes } from 'react';
export default class TextareaField extends React.Component {
  render() {
    let {
      characterCount,
      className,
      label,
      name,
      onChange,
      type,
      value
    } = this.props;

    return <div className="cf-form-textarea cf-form-textarea--full-width">
      <label className="question-label" htmlFor={name}>{label || name}</label>
      <textarea
        className="cf-form-textarea"
        name={name}
        id={name}
        onChange={onChange}
        type={type}
        value={value}
      />
      {characterCount &&
        <p>Character Count: {value.length}</p>
      }
    </div>;
  }
}

TextareaField.propTypes = {
  characterCount: PropTypes.bool,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.string
};

