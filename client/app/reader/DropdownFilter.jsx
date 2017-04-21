import React, { PropTypes } from 'react';

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
      <div className="cf-clear-filter-row" onClick={this.props.clearFilters}>
        <div className="cf-clear-filter-button-wrapper">
          <button className="cf-text-button" onClick={this.props.clearFilters}
              disabled={!this.props.isClearEnabled}>
            Clear category filter
          </button>
        </div>
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

  onGlobalClick = (event) => {
    if (!this.rootElem) {
      return;
    }

    const clickIsInsideThisComponent = this.rootElem.contains(event.target);

    if (!clickIsInsideThisComponent) {
      this.props.handleClose();
    }
  }
}

DropdownFilter.propTypes = {
  children: PropTypes.node,
  baseCoordinates: PropTypes.shape({
    bottom: PropTypes.number.isRequired,
    right: PropTypes.number.isRequired
  }),
  isClearEnabled: PropTypes.bool,
  clearFilters: PropTypes.func,
  handleClose: PropTypes.func
};

export default DropdownFilter;
