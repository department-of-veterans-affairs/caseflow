import React from 'react';
import PropTypes from 'prop-types';
import { SelectedFilterIcon } from './SelectedFilterIcon';
import { UnselectedFilterIcon } from './UnselectedFilterIcon';
class FilterIcon extends React.PureComponent {
  render() {
    const {
      handleActivate, label, getRef, selected
    } = this.props;

    const handleKeyDown = (event) => {
      if (event.key === ' ' || event.key === 'Enter') {
        handleActivate(event);
        event.preventDefault();
      }
    };

    const className = 'table-icon';

    const props = {
      role: 'button',
      getRef,
      'aria-label': label,
      className,
      tabIndex: '0',
      onKeyDown: handleKeyDown,
      onClick: handleActivate,
    };

    if (selected) {
      return <SelectedFilterIcon {...props} />;
    }

    return <UnselectedFilterIcon {...props} />;
  }
}

FilterIcon.propTypes = {
  label: PropTypes.string,
  iconName: PropTypes.string,
  handleActivate: PropTypes.func,
  getRef: PropTypes.func,
  className: PropTypes.string,
  selected: PropTypes.bool,
};

export default FilterIcon;
