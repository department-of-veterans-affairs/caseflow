import React, { PropTypes } from 'react';
export default class Checkbox extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      checked: props.checked
    };

    this.defaultHandler = this.defaultHandler.bind(this);
  }


  defaultHandler(event) {
    this.setState({
      checked: !this.state.checked
    });

    if (this.props.onChange) {
      this.props.onChange(event);
    }
  }

  render() {
    let {
      label,
      name
    } = this.props;

    return <div className="cf-form-checkboxes">
      <div className="cf-form-checkbox">

      <input
        name={name}
        onChange={this.defaultHandler}
        type="checkbox"
        id={name}
        checked={this.state.checked}
      />
      <label className="question-label" htmlFor={name}>{label || name}</label>
      </div>
    </div>;
  }
}

Checkbox.propTypes = {
  checked: PropTypes.bool,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func
};
