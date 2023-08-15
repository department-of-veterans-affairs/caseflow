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

class ReaderTableDropdownFilter extends React.PureComponent {
  constructor() {
    super();
    this.state = {
      rootElemWidth: null
    };
  }

  render() {
    const { children, name } = this.props;

    const style = {
      top: '25px',
      right: 0
    };

    const rel = {
      position: 'relative'
    };

    return <div style={rel}>

      <div className="cf-dropdown-filter" style={style} ref={(rootElem) => {
        this.rootElem = rootElem;
      }}>
        {this.props.addClearFiltersRow &&
        <div>
          {React.cloneElement(React.Children.only(children), {
            dropdownFilterViewListStyle,
            dropdownFilterViewListItemStyle
          })}
          <div className="cf-clear-filter-row">
            <button className="cf-text-button" onClick={this.props.clearFilters}
              disabled={!this.props.isClearEnabled}>
              <div className="cf-clear-filter-button-wrapper">
                Clear {name} filter
              </div>
            </button>
          </div>
        </div>
        }

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

ReaderTableDropdownFilter.propTypes = {
  children: PropTypes.node,
  isClearEnabled: PropTypes.bool,
  clearFilters: PropTypes.func,
  handleClose: PropTypes.func,
  addClearFiltersRow: PropTypes.bool
};

export default ReaderTableDropdownFilter;
