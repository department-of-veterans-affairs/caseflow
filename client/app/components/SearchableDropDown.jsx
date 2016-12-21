import React, { PropTypes } from 'react';
export default class SearchableDropDown extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      filteredOptions: this.props.options,
      showDropDown: false,
      hovered: 0,
      selected: null,
      searching: ''
    };
  }

  select(value) {
    this.setState({
      selected: value,
      searching: value,
      showDropDown: false
    });

    if (this.props.onChange) {
      this.props.onChange({target: {value: value}});
    }
  }

  onInputClick = (event) => {
    this.setState({
      filteredOptions: this.props.options,
      showDropDown: true,
      searching: ''
    });
  }

  onBlur = (event) => {
    this.select(this.state.selected);
  }

  onMouseOver = (id) => {
    return (event) => {
      this.setState({
        hovered: id
      })
    }
  }

  onMouseDown = (value) => {
    return (event) => {
      this.select(value);
    }
  }

  onChange = (event) => {
    this.setState({
      filteredOptions: this.props.options.filter((option) => {return (new RegExp(event.target.value, 'gi')).test(option)}),
      selected: null,
      searching: event.target.value,
      showDropDown: true,
      hovered: 0
    });
  }

  onKeyUp = (event) => {
    if (event.keyCode === 13) {
      this.select(this.state.filteredOptions[this.state.hovered]);
    }
    if (event.keyCode === 38) {
      this.setState({
        hovered: Math.max(this.state.hovered - 1, 0)
      });
    }
    if (event.keyCode === 40) {
      this.setState({
        hovered: Math.min(this.state.hovered + 1, this.props.options.length - 1)
      });
    }
  }

  render() {
    let {
      errorMessage,
      label,
      name,
      options,
      required,
      value,
      readOnly
    } = this.props;


    return <div className="cf-form-dropdown">
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">(Required)</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <input
        className="cf-dropdown-input"
        type="text"
        onClick={this.onInputClick}
        onBlur={this.onBlur}
        value={this.state.searching}
        onChange={this.onChange}
        onKeyUp={this.onKeyUp}
      />
      {this.state.showDropDown &&
        <div className="dropdown">
          <div className="dropdown-content">
            { this.state.filteredOptions.map((option, index) =>
              <div
                onMouseOver={this.onMouseOver(index)}
                onMouseDown={this.onMouseDown(option)}
                className={"cf-dropdown-item" + (this.state.hovered === index ? " cf-dropdown-item-hover" : "")}
                value={option}
                id={`${name}_${option}`}
                key={index}>{option}
              </div>
            )}
            { this.state.filteredOptions.length === 0 &&
              <div className="cf-dropdown-item">
                No results found
              </div>
            }
          </div>
        </div>
      }
    </div>;
  }
}

SearchableDropDown.propTypes = {
  errorMessage: PropTypes.string,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array,
  readOnly: PropTypes.bool,
  required: PropTypes.bool,
  value: PropTypes.string
};
