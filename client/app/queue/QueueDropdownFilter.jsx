import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { css } from 'glamor';

const dropdownFilterViewListStyle = css({
  margin: 0
});
const dropdownFilterViewListItemStyle = css(
  {
    padding: '14px',
    ':hover':
    {
      backgroundColor: '#5b616b',
      color: COLORS.WHITE
    }
  }
);

class QueueDropdownFilter extends React.PureComponent {
  constructor() {
    super();
    this.state = {
      rootElemWidth: null
    };
  }

  render() {
    const { children } = this.props;

    const rel = {
      position: 'relative'
    };

    return <div style={rel}>
      <div className="cf-dropdown-filter" ref={(rootElem) => {
        this.rootElem = rootElem;
      }}>
        {this.props.addClearFiltersRow &&
          <div className="cf-filter-option-row clear-wrapper">
            <button className="cf-text-button cf-btn-link" onClick={this.props.clearFilters}
              disabled={!this.props.isClearEnabled}>
              Clear filter
            </button>
          </div>
        }
        {React.cloneElement(React.Children.only(children), {
          dropdownFilterViewListStyle,
          dropdownFilterViewListItemStyle
        })}
      </div>
    </div>;
  }

  componentDidMount() {
    document.addEventListener('click', this.onGlobalClick, true);
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

QueueDropdownFilter.propTypes = {
  children: PropTypes.node,
  isClearEnabled: PropTypes.bool,
  clearFilters: PropTypes.func,
  handleClose: PropTypes.func,
  addClearFiltersRow: PropTypes.bool,
  name: PropTypes.string,
};

export default QueueDropdownFilter;
