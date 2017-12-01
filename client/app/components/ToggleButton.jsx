import React from 'react';
import PropTypes from 'prop-types';

export default class ToggleButton extends React.Component {
  handleClick = (name) => () => {
    this.props.onClick(name);
  }

  render() {
    const {
      children,
      active
    } = this.props;

   // Traverse/Iterate the ‘children’ property, invoking a method
   // for each child and adding the result to an array.

    const mappedChildren = React.Children.map(children, (child) => {
      return React.cloneElement(child, {
        classNames: active === child.props.name ? ['cf-toggle-box-shadow usa-button'] : ['usa-button-outline'],
        onClick: this.handleClick(child.props.name)
      }
     );
    });

    return <div className="cf-toggle-button">{mappedChildren}</div>;
  }
}

ToggleButton.propTypes = {
  active: PropTypes.string,
  children: PropTypes.node
};
