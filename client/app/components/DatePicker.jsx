import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import FilterIcon from './icons/FilterIcon';
import SearchableDropdown from '../components/SearchableDropdown';

const datePickerStyle = css({
  paddingLeft: '1rem',
  paddingTop: '0.3rem',
  verticalAlign: 'middle',
  position: 'relative',
  fontWeight: 'normal',
  top: '0.15rem',
  '& svg': {
    cursor: 'pointer'
  },
  '& .date-picker.right': {
    right: 0,
  },
  '& .date-picker.left': {
    left: '10px',
  }
});

const menuStyle = css({
  position: 'absolute',
  background: 'white',
  top: '24px',
  width: '250px',
  border: '1px solid #CCC',
  '& .input-wrapper': {
    padding: '0 1rem 2.5rem',
    '& input': {
      margin: '0'
    },
    '& label': {
      padding: '0 0 8px 0',
      margin: '0'
    }
  },
  '& .clear-wrapper': {
    borderBottom: '1px solid #d6d7d9',
    textAlign: 'center',
    padding: '2rem',
    marginBottom: '2rem',
    '& a': {
      cursor: 'pointer'
    }
  },
  '& .button-wrapper': {
    borderTop: '1px solid #d6d7d9',
    textAlign: 'center',
    padding: '0.75rem',
    '& button': {
      margin: '0'
    }
  }
});

class DatePicker extends React.PureComponent {
  constructor(props) {
    super(props);

    const position = (props.settings && props.settings.position) || 'left';

    this.state = {
      open: false,
      mode: '',
      startDate: '',
      endDate: '',
      position
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

      if (values) {
        const splitValues = values[0].split(',');

        if (splitValues) {
          this.setState({ mode: splitValues[0], startDate: splitValues[1], endDate: splitValues[2] });
        }
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

  buttonDisabled = () => {
    let disabled = true;

    if (this.state.mode === 'between') {
      disabled = this.state.startDate === '' || this.state.endDate === '';
    } else if (this.state.mode !== '') {
      disabled = this.state.startDate === '';
    }

    return disabled;
  }

  clearFilter = () => {
    this.setState({ mode: '', startDate: '', endDate: '' });
  }

  updateMode = (mode) => {
    this.setState({ mode });
    if (mode !== 'between') {
      this.setState({ endDate: '' });
    }
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
          <div className={`date-picker ${this.state.position}`} {...menuStyle}>
            <div className="clear-wrapper">
              <a onClick={() => this.clearFilter()}>Clear filter</a>
            </div>
            <div className="input-wrapper">
              <SearchableDropdown
                name="Date filter parameters"
                options={[
                  { value: 'between', label: 'Between these dates' },
                  { value: 'before', label: 'Before this date' },
                  { value: 'after', label: 'After this date' },
                  { value: 'on', label: 'On this date' }
                ]}
                searchable
                onChange={(option) => this.updateMode(option.value)}
                filterOption={() => true}
                value={this.state.mode} />
            </div>

            {this.state.mode !== '' &&
              <div className="input-wrapper">
                <label aria-label="start-date"
                  htmlFor="start-date">{this.state.mode === 'between' ? 'From' : 'Date'}</label>
                <input
                  id="start-date"
                  name="start-date"
                  defaultValue={this.state.startDate}
                  type="date"
                  onChange={(event) => this.setState({ startDate: event.target.value })}
                />
              </div>
            }

            {this.state.mode === 'between' &&
              <div className="input-wrapper">
                <label aria-label="end-date" htmlFor="end-date">To</label>
                <input
                  id="end-date"
                  name="end-date"
                  defaultValue={this.state.endDate}
                  type="date"
                  onChange={(event) => this.setState({ endDate: event.target.value })}
                />
              </div>
            }
            <div className="button-wrapper">
              <button disabled={this.buttonDisabled()}
                onClick={() => this.apply()}>Apply Filter</button>
            </div>
          </div>
      }
    </span>;
  }
}

DatePicker.propTypes = {
  onChange: PropTypes.func,
  values: PropTypes.array,
  getRef: PropTypes.func,
  label: PropTypes.string,
  settings: PropTypes.object,
};

export default DatePicker;
