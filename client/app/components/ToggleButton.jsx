import React from 'react';
import Button from './Button';
import PropTypes from 'prop-types';

export default class ToggleButton extends React.Component {

  handleClick = (event) => {
    this.props.onClick(event.target.id);
  }
  render() {
    let {
      labels,
      active,
      activeButton,
      inactiveButton
    } = this.props;
    const primaryClassShadow = [...activeButton, 'cf-toggle-box-shadow'];

    return <div className ="cf-toggle-button">
    {labels.map((label) =>

    <Button
      id={label.id}
      key = {label.id}
      name={label.text}
      classNames={active === label.id ?
      primaryClassShadow : inactiveButton}
      onClick ={this.handleClick}
     />
   )}
   </div>;
  }
}

ToggleButton.propTypes = {
  labels: PropTypes.arrayOf(PropTypes.object),
  onClick: PropTypes.func,
  active: PropTypes.string,
  activeButton: PropTypes.arrayOf(PropTypes.string),
  inactiveButton: PropTypes.arrayOf(PropTypes.string)
};
