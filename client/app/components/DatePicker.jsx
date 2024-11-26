import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import FilterIcon from './icons/FilterIcon';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import COPY from '../../COPY';
import moment from 'moment-timezone';
<<<<<<< HEAD
=======
import DateSelector from './DateSelector';
>>>>>>> origin/feature/APPEALS-49620

const datePickerStyle = css({
  paddingLeft: '0.95rem',
  paddingTop: '0.3rem',
  verticalAlign: 'middle',
  position: 'relative',
  fontWeight: 'normal',
  display: 'table-cell',
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
  width: '250px',
  border: '1px solid #CCC',
  boxShadow: '5px 5px 4px -3px #d6d7d9',
  zIndex: '1',
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
  },
  '& .quick-buttons': {
    padding: '0 0 2rem 0',
    textAlign: 'center',
    borderBottom: '1px solid #d6d7d9',
    marginBottom: '2rem',
  }
});

<<<<<<< HEAD
=======
const defaultOptions = [
  { value: 'between', label: COPY.DATE_PICKER_DROPDOWN_BETWEEN },
  { value: 'before', label: COPY.DATE_PICKER_DROPDOWN_BEFORE },
  { value: 'after', label: COPY.DATE_PICKER_DROPDOWN_AFTER },
  { value: 'on', label: COPY.DATE_PICKER_DROPDOWN_ON }
];

const additionalOptions = [
  { value: 'last7', label: COPY.DATE_PICKER_DROPDOWN_7 },
  { value: 'last30', label: COPY.DATE_PICKER_DROPDOWN_30 },
  { value: 'last365', label: COPY.DATE_PICKER_DROPDOWN_365 },
  { value: 'all', label: COPY.DATE_PICKER_DROPDOWN_ALL }
];

>>>>>>> origin/feature/APPEALS-49620
/* Custom filter method to pass in a QueueTable column object */
/* This is called for every row of data in the table */
/* rowValue is a date string such as '5/15/2024' */
/* filterValues is the array of filter options such as ['between,2024-05-01,2024-05-31']
/* It returns true or false if the row belongs in the data still  */
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
<<<<<<< HEAD
=======
      } else if (mode === 'last7') {
        const startDate = moment().subtract(7, 'days').
          valueOf();
        const endDate = moment();

        pick = rowDate >= startDate && rowDate <= endDate;
      } else if (mode === 'last30') {
        const startDate = moment().subtract(30, 'days').
          valueOf();
        const endDate = moment();

        pick = rowDate >= startDate && rowDate <= endDate;
      } else if (mode === 'last365') {
        const startDate = moment().subtract(365, 'days').
          valueOf();
        const endDate = moment().valueOf();

        pick = rowDate >= startDate && rowDate <= endDate;
>>>>>>> origin/feature/APPEALS-49620
      }
    }
  }

  return pick;
};

class DatePicker extends React.PureComponent {
  constructor(props) {
    super(props);

    const position = (props.settings && props.settings.position) || 'left';
    const buttons = (props.settings && props.settings.buttons) || false;
    const selected = (props.selected && props.selected) || false;
<<<<<<< HEAD
=======
    const noFutureDates = (props.settings && props.settings.noFutureDates) || false;
>>>>>>> origin/feature/APPEALS-49620

    this.state = {
      open: false,
      mode: '',
      startDate: '',
      endDate: '',
      position,
      buttons,
<<<<<<< HEAD
      selected
=======
      selected,
      noFutureDates
>>>>>>> origin/feature/APPEALS-49620
    };
  }

  apply() {
    const { onChange } = this.props;

<<<<<<< HEAD
=======
    if (this.state.mode === 'all') {
      this.clearFilter();
      this.hideDropdown();

      return true;
    }

>>>>>>> origin/feature/APPEALS-49620
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

      if (values && values.length) {
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
    return this.state.open || this.state.selected;
  }

<<<<<<< HEAD
=======
  isDateInFuture = (date) => {
    if (!date) {
      return false;
    }

    return Boolean(Date.parse(date) > Date.now());
  }

>>>>>>> origin/feature/APPEALS-49620
  buttonDisabled = () => {
    let disabled = true;

    if (this.state.mode === 'between') {
<<<<<<< HEAD
      disabled = this.state.startDate === '' || this.state.endDate === '';
=======
      if (this.state.startDate === '' || this.state.endDate === '') {
        disabled = true;
      } else if (this.state.noFutureDates &&
        (this.isDateInFuture(this.state.startDate) || this.isDateInFuture(this.state.endDate))) {
        disabled = true;
      } else {
        const startDate = moment(`${this.state.startDate} 00:00:00`).valueOf();
        const endDate = moment(`${this.state.endDate} 23:59:59`).valueOf();

        disabled = startDate >= endDate;
      }

    } else if (this.state.noFutureDates && this.isDateInFuture(this.state.startDate)) {
      disabled = true;
    } else if (this.state.mode === 'all') {
      disabled = false;
>>>>>>> origin/feature/APPEALS-49620
    } else if (this.state.mode !== '') {
      disabled = this.state.startDate === '';
    }

    return disabled;
  }

  clearFilter = () => {
    const { onChange } = this.props;

    this.setState({ mode: '', startDate: '', endDate: '' });

    if (onChange) {
      onChange('', true);
    }

    this.hideDropdown();
  }

  updateMode = (mode) => {
<<<<<<< HEAD
=======
    const format = 'YYYY-MM-DD';

>>>>>>> origin/feature/APPEALS-49620
    this.setState({ mode });
    if (mode !== 'between') {
      this.setState({ endDate: '' });
    }
<<<<<<< HEAD
=======

    if (mode === 'last7') {
      this.setState({ startDate: moment().subtract(7, 'days').
        format(format) });
    } else if (mode === 'last30') {
      this.setState({ startDate: moment().subtract(30, 'days').
        format(format) });
    } else if (mode === 'last365') {
      this.setState({ startDate: moment().subtract(365, 'days').
        format(format) });
    }
>>>>>>> origin/feature/APPEALS-49620
  }

  quickButtons = (option) => {
    let mode = '';
    let startDate = '';
    let endDate = '';
    const format = 'YYYY-MM-DD';
    const { onChange } = this.props;

    if (option === 30) {
      mode = 'between';
      startDate = moment().subtract(30, 'days').
        format(format);
      endDate = moment().format(format);
    }

    if (onChange) {
      onChange(`${ mode },${ startDate },${ endDate}`, false);
    }

    this.hideDropdown();
  }

<<<<<<< HEAD
  render() {
=======
  getOptions = () => {
    if (this.props.settings?.additionalOptions) {
      const options = defaultOptions.concat(additionalOptions);

      return options;
    }

    return defaultOptions;
  };

  startDateErrorMessage = () => {
    if (this.state.noFutureDates && this.state.startDate && this.isDateInFuture(this.state.startDate)) {
      return COPY.DATE_PICKER_NO_FUTURE_DATES_ERROR_MESSAGE;
    }

    return '';
  }

  endDateErrorMessage = () => {
    if (this.state.noFutureDates && this.state.endDate && this.isDateInFuture(this.state.endDate)) {
      return COPY.DATE_PICKER_NO_FUTURE_DATES_ERROR_MESSAGE;
    }

    if (this.state.mode === 'between' && this.state.startDate !== '' && this.state.endDate !== '') {
      const startDate = moment(`${this.state.startDate} 00:00:00`).valueOf();
      const endDate = moment(`${this.state.endDate} 23:59:59`).valueOf();

      if (startDate >= endDate) {
        return COPY.DATE_PICKER_BETWEEN_DATES_ERROR_MESSAGE;
      }
    }

    return '';
  }

  render() {

>>>>>>> origin/feature/APPEALS-49620
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

            {this.state.buttons &&
              <div className="quick-buttons">
                <Button onClick={() => this.quickButtons(30)} name={COPY.DATE_PICKER_QUICK_BUTTON_30} />
              </div>
            }

            <div className="input-wrapper">
              <SearchableDropdown
                name={COPY.DATE_PICKER_DROPDOWN_LABEL}
<<<<<<< HEAD
                options={[
                  { value: 'between', label: COPY.DATE_PICKER_DROPDOWN_BETWEEN },
                  { value: 'before', label: COPY.DATE_PICKER_DROPDOWN_BEFORE },
                  { value: 'after', label: COPY.DATE_PICKER_DROPDOWN_AFTER },
                  { value: 'on', label: COPY.DATE_PICKER_DROPDOWN_ON }
                ]}
=======
                options={this.getOptions()}
>>>>>>> origin/feature/APPEALS-49620
                searchable
                onChange={(option) => this.updateMode(option.value)}
                filterOption={() => true}
                value={this.state.mode} />
            </div>

<<<<<<< HEAD
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
=======
            {additionalOptions.some((option) => option.value === this.state.mode) ?
              null :
              <div className="input-wrapper">
                <DateSelector
                  label={this.state.mode === 'between' ? COPY.DATE_PICKER_FROM : COPY.DATE_PICKER_DATE}
                  name="start-date"
                  id="start-date"
                  noFutureDates={this.state.noFutureDates}
                  defaultValue={this.state.startDate}
                  errorMessage={this.startDateErrorMessage()}
                  onChange={(value) => this.setState({ startDate: value })}
                  type="date"
>>>>>>> origin/feature/APPEALS-49620
                />
              </div>
            }

            {this.state.mode === 'between' &&
              <div className="input-wrapper">
<<<<<<< HEAD
                <label aria-label="end-date" htmlFor="end-date">{COPY.DATE_PICKER_TO}</label>
                <input
                  id="end-date"
                  name="end-date"
                  defaultValue={this.state.endDate}
                  type="date"
                  onChange={(event) => this.setState({ endDate: event.target.value })}
=======
                <DateSelector
                  label={COPY.DATE_PICKER_TO}
                  name="end-date"
                  id="end-date"
                  noFutureDates={this.state.noFutureDates}
                  defaultValue={this.state.endDate}
                  errorMessage={this.endDateErrorMessage()}
                  onChange={(value) => this.setState({ endDate: value })}
                  type="date"
>>>>>>> origin/feature/APPEALS-49620
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
  selected: PropTypes.bool,
};

export default DatePicker;
