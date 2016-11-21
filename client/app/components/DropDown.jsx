import React, { PropTypes } from 'react';
export default class DropDown extends React.Component {
  render() {
    let {
      label,
      name,
      onChange,
      options
    } = this.props;

    return (<div className="cf-form-dropdown">
      <label className="question-label">{label || name}</label>
      <select>
        {options.map((option, index) => (
          <option key={index}>{option}</option>
        ))}
      </select>
    </div>);
  }
}

DropDown.defaultProps = {
}

