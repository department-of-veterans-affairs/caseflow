import React, { PropTypes } from 'react';
export default class TextField extends React.Component {
  render() {
    let {
      label,
      name,
      onChange,
      readOnly,
      type,
      value,
      validationError,
      invisible,
      placeholder
    } = this.props;

    return (<div className={"cf-form-textinput" + (invisible ? " cf-invisible" : "")}>
      <label className="question-label" htmlFor={name}>{label || name}</label>
      <input
        className="cf-form-textinput"
        name={name}
        id={name}
        onChange={onChange}
        type={type}
        value={value}
        readOnly={readOnly}
        placeholder={placeholder}
      />
      {validationError && <div className="cf-validation">
        <span>{validationError}</span>
      </div>}
    </div>);
  }
}

TextField.defaultProps = {
  type: 'text'
};

TextField.propTypes = {
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: function(props) {
    if (!props.readOnly) {
      if (typeof props.onChange !== 'function') {
        return new Error('If TextField is not ReadOnly, then onChange must be defined');
      }
    }
  },
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.string,
  readOnly: PropTypes.bool,
  invisible: PropTypes.bool,
  placeholder: PropTypes.string
};
