import React from 'react';
import PropTypes from 'prop-types';
import { SelectedFilterIcon, UnselectedFilterIcon } from '../components/RenderFunctions';

class FilterIcon extends React.PureComponent {
  render() {
    const {
      handleActivate, label, getRef, selected, idPrefix
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
      onClick: handleActivate
    };

    if (selected) {
      return <SelectedFilterIcon {...props} idPrefix={idPrefix} />;
    }

    return <UnselectedFilterIcon {...props} />;
  }
}

FilterIcon.propTypes = {
  label: PropTypes.string.isRequired,
  iconName: PropTypes.string,
  handleActivate: PropTypes.func,
  getRef: PropTypes.func,
  idPrefix: PropTypes.string.isRequired,
  className: PropTypes.string
};

export default FilterIcon;
