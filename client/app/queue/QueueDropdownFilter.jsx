import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { css } from 'glamor';
import { startCase } from 'lodash';

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
    const { children, name } = this.props;

    // Some of the filter names are camelCase, which would be displayed to the user.
    // To make this more readable, convert the camelCase text to regular casing.
    const displayName = startCase(name);

    const rel = {
      position: 'relative'
    };

    return <div style={rel}>
      <div className="cf-dropdown-filter" style={{ top: '10px' }} ref={(rootElem) => {
        this.rootElem = rootElem;
      }}>
        {this.props.addClearFiltersRow &&
          <div className="cf-filter-option-row">
            <button className="cf-text-button" onClick={this.props.clearFilters}
              disabled={!this.props.isClearEnabled}>
              <div className="cf-clear-filter-button-wrapper">
                Clear {displayName} filter
              </div>
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
