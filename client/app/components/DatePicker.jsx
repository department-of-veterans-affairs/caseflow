import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import FilterIcon from './icons/FilterIcon';

const datePickerStyle = css({
  display: 'table-cell',
  paddingLeft: '1rem',
  paddingTop: '0.3rem',
  verticalAlign: 'middle',
  position: 'relative',
  '& svg': {
    cursor: 'pointer'
  }
});

const menuStyle = css({
  position: 'absolute',
  background: 'white',
  right: 0,
  top: '52px',
  width: '200px',
  height: '200px',
  border: '1px solid #CCC',
  padding: '1rem'
});

class DatePicker extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      open: false,
      mode: 'between',
      startDate: '',
      endDate: '',
    };
  }

  apply() {
    const { onChange } = this.props;

    if (onChange) {
      onChange(`${this.state.mode },${ this.state.startDate },${ this.state.endDate}`);
    }
  }

  toggleDropdown = () => {
    const open = !this.state.open;

    this.setState({ open });
    if (open) {
      const { values } = this.props;
      const splitValues = values[0].split(',');

      if (splitValues) {
        this.setState({ mode: splitValues[0], startDate: splitValues[1], endDate: splitValues[2] });
      }
    }
  }

  hideDropdown = () => this.setState({ open: false });

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
      this.hideDropdown();
    }
  }

  isFilterOpen = () => {
    return this.state.open;
  }

  render() {
    return <span {...datePickerStyle} ref={(rootElem) => {
      this.rootElem = rootElem;
    }}>
      <FilterIcon
        aria-label={this.props.label}
        label={this.props.label}
        getRef={this.props.getRef}
        selected={this.isFilterOpen()}
        handleActivate={this.toggleDropdown} />

      {this.state.open &&
          <div {...menuStyle}>
            <div>
              <input
                label="Start date"
                name="start-date"
                defaultValue={this.state.startDate}
                type="date"
                onChange={(event) => this.setState({ startDate: event.target.value })}
              />
            </div>
            <div>
              <input
                label="End date"
                name="end-date"
                defaultValue={this.state.endDate}
                type="date"
                onChange={(event) => this.setState({ endDate: event.target.value })}
              />
            </div>
            <div><button disabled={this.state.startDate === '' || this.state.endDate === ''}
              onClick={() => this.apply()}>Apply</button></div>
          </div>
      }
    </span>;
  }
}

DatePicker.propTypes = {
  onChange: PropTypes.func,
  values: PropTypes.array,
  getRef: PropTypes.func,
  label: PropTypes.string
};

export default DatePicker;
