import React, { PropTypes } from 'react';
import IconButton from '../components/IconButton';

class DropdownFilter extends React.PureComponent {
  constructor() {
    super();
    this.state = {
      rootElemWidth: null
    };
  }

  render() {
    const { children, baseCoordinates } = this.props;

    if (!baseCoordinates) {
      return null;
    }

    let style;

    if (this.state.rootElemWidth) {
      const topOffset = 5;

      style = {
        top: baseCoordinates.bottom + topOffset,
        left: baseCoordinates.right - this.state.rootElemWidth
      };
    } else {
      style = { left: '-99999px' };
    }

    return <div className="cf-dropdown-filter" style={style} ref={(rootElem) => {
      this.rootElem = rootElem;
    }}>
      <div className="cf-clear-filter-row">
        <button className="cf-text-button" onClick={this.props.clearFilters}
            disabled={!this.props.isClearEnabled}>
          Clear category filter
        </button>
        <IconButton iconName="fa-times"
          handleActivate={this.props.clearFilters} label="Clear filters" />
      </div>
      {children}
    </div>;
  }

  componentDidMount() {
    document.addEventListener('click', this.onGlobalClick, true);

    if (this.rootElem) {
      this.setState({
        rootElemWidth: this.rootElem.clientWidth
      });
    }
  }

  componentWillUnmount() {
    document.removeEventListener('click', this.onGlobalClick);
  }

  onGlobalClick = () => {
    const clickIsInsideThisComponent = () => {
      let node = event.target;

      // eslint-disable-next-line no-cond-assign
      while (node = node.parentNode) {
        if (node === this.rootElem) {
          return true;
        }
      }

      return false;
    };

    if (!clickIsInsideThisComponent()) {
      this.props.handleClose();
    }
  }
}

export default DropdownFilter;
