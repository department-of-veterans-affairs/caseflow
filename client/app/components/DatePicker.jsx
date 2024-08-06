import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import FilterIcon from './icons/FilterIcon';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import COPY from '../../COPY';
import moment from 'moment-timezone';

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
    padding: '1rem',
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

/* Custom filter method to pass in a QueueTable column object */
/* This called for every row of data in the table */
/* rowValue is a date string such as '5/15/2024' */
/* filterValues is the array of filter options such as ['between,2024-05-01,2024-05-31']
/* It returns true or false if the row belongs in the data still */
export const datePickerFilterValue = (rowValue, filterValues) => {
  let pick = false;
  const rowDate = moment(rowValue).valueOf();

  if (filterValues.length && rowDate) {
    const filterOptions = filterValues[0].split(',');

    if (filterOptions) {
      const mode = filterOptions[0];

      if (mode === 'between') {
        const startDate = moment(`${filterOptions[1]} 00:00:00`).valueOf();
        const endDate = moment(`${filterOptions[2]} 23:59:59`).valueOf();

        pick = rowDate >= startDate && rowDate <= endDate;
      } else if (mode === 'before') {
        const date = moment(`${filterOptions[1]} 00:00:00`).valueOf();

        pick = rowDate < date;
      } else if (mode === 'after') {
        const date = moment(`${filterOptions[1]} 23:59:59`).valueOf();

        pick = rowDate > date;
      } else if (mode === 'on') {
        const startDate = moment(`${filterOptions[1]} 00:00:00`).valueOf();
        const endDate = moment(`${filterOptions[1]} 23:59:59`).valueOf();

        pick = rowDate >= startDate && rowDate <= endDate;
      }
    }
  }

  return pick;
};

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

    this.hideDropdown();
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
    const { onChange } = this.props;

    this.setState({ mode: '', startDate: '', endDate: '' });

    if (onChange) {
      onChange('');
    }

    this.hideDropdown();
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
              <Button linkStyling onClick={() => this.clearFilter()} name={COPY.DATE_PICKER_CLEAR} />
            </div>
            <div className="input-wrapper">
              <SearchableDropdown
                name={COPY.DATE_PICKER_DROPDOWN_LABEL}
                options={[
                  { value: 'between', label: COPY.DATE_PICKER_DROPDOWN_BETWEEN },
                  { value: 'before', label: COPY.DATE_PICKER_DROPDOWN_BEFORE },
                  { value: 'after', label: COPY.DATE_PICKER_DROPDOWN_AFTER },
                  { value: 'on', label: COPY.DATE_PICKER_DROPDOWN_ON }
                ]}
                searchable
                onChange={(option) => this.updateMode(option.value)}
                filterOption={() => true}
                value={this.state.mode} />
            </div>

            {this.state.mode !== '' &&
              <div className="input-wrapper">
                <label aria-label="start-date"
                  htmlFor="start-date">
                  {this.state.mode === 'between' ? COPY.DATE_PICKER_FROM : COPY.DATE_PICKER_DATE}</label>
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
                <label aria-label="end-date" htmlFor="end-date">{COPY.DATE_PICKER_TO}</label>
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
                onClick={() => this.apply()}>{COPY.DATE_PICKER_APPLY}</button>
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
