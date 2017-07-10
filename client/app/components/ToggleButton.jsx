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
      active
    } = this.props;

    return <div className="usa-grid">
    <Button
      id={labels[0].id}
      name={labels[0].text}
      classNames={active === labels[0].id ?
      ['cf-primary-default button_wrapper'] : ['cf-secondary-default usa-button-outline']}
      onClick ={this.handleClick}
     />
     <Button
        id={labels[1].id}
        name = {labels[1].text}
        classNames={active === labels[1].id ?
        ['cf-primary-default button_wrapper'] : ['cf-secondary-default usa-button-outline']}
        onClick ={this.handleClick}
      />

   </div>;
  }
}

ToggleButton.propTypes = {
   // labels: PropTypes.arrayOf(),
  onClick: PropTypes.func,
  active: PropTypes.string
};
