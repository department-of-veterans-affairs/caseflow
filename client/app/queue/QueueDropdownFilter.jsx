import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { css } from 'glamor';
import ReceiptDatePicker from '../components/ReceiptDatePicker';
import TaskCompletedDatePicker from '../components/TaskCompletedDatePicker';

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

const receiptDateFilterStates = {
  UNINITIALIZED: '',
  BETWEEN: 0,
  BEFORE: 1,
  AFTER: 2,
  ON: 3
};

const taskCompletedDateFilterStates = {
  UNINITIALIZED: '',
  BETWEEN: 0,
  BEFORE: 1,
  AFTER: 2,
  ON: 3
};

const convertStringToDate = (stringDate) => {
  const date = new Date();
  const splitVals = stringDate.split('-');

  date.setFullYear(Number(splitVals[0]));
  // the datepicker component returns months from 1-12. Javascript dates count months from 0-11
  // this offsets it so they match.
  date.setMonth(Number(splitVals[1] - 1));
  date.setDate(Number(splitVals[2]));

  return date;
};

class QueueDropdownFilter extends React.PureComponent {
  constructor() {
    super();
    this.state = {
      rootElemWidth: null,
      receiptDateState: -1,
      receiptDatePrimaryValue: '',
      receiptDateSecondaryValue: '',
      taskCompletedDateState: -1,
      taskCompletedDatePrimaryValue: '',
      taskCompletedDateSecondaryValue: '',
      dateErrorsFrom: [],
      dateErrorsTo: [],
    };
  }

  setreceiptDateState = (value) => {
    this.setState({ receiptDateState: value.value });
  };

  validateDate = (date, type, filterType) => {
    let foundErrors = [];
    let primaryDate = '';
    let secondaryDate = '';
    let currentSelector = '';
    let messageText = '';

    if (filterType === 'VADOR') {
      currentSelector = this.state.receiptDateState;
      primaryDate = this.state.receiptDatePrimaryValue;
      secondaryDate = this.state.receiptDateSecondaryValue;
      messageText = 'Receipt date';
    } else {
      currentSelector = this.state.taskCompletedDateState;
      primaryDate = this.state.taskCompletedDatePrimaryValue;
      secondaryDate = this.state.taskCompletedDateSecondaryValue;
      messageText = 'Date completed';
    }

    if (currentSelector === 0) {
      if (type === 'fromDate') {
        if (secondaryDate !== '' && date > secondaryDate) {
          foundErrors = [...foundErrors, { key: type, message: 'From date cannot occur after to date.' }];
        }
      } else if (date < primaryDate) {
        foundErrors = [...foundErrors, { key: type, message: 'To date cannot occur before from date.' }];
      }
    }

    // Prevent the date from being picked past the current day.
    if (convertStringToDate(date) > new Date()) {
      foundErrors = [...foundErrors, { key: type, message: `${messageText} cannot occur in the future.` }];
    }

    if (type === 'fromDate') {
      this.setState({ dateErrorsFrom: foundErrors });
      if (secondaryDate !== '' &&
      date <= secondaryDate &&
      convertStringToDate(secondaryDate) <= new Date()) {
        this.setState({ dateErrorsTo: foundErrors });
      }
    } else {
      this.setState({ dateErrorsTo: foundErrors });
      if (primaryDate !== '' &&
      date >= primaryDate &&
      convertStringToDate(primaryDate) <= new Date()) {
        this.setState({ dateErrorsFrom: [] });
      }
    }

    return foundErrors;
  };

  setTaskCompletedDateState = (value) => {
    this.setState({ taskCompletedDateState: value.value });
  };

  handleDateChange = (value) => {
    this.validateDate(value, 'fromDate', 'VADOR');
    this.setState({ receiptDatePrimaryValue: value });
  }

  handleTaskCompletedDateChange = (value) => {
    this.validateDate(value, 'fromDate', 'FDATE');
    this.setState({ taskCompletedDatePrimaryValue: value });
  }

  // Used when the between dates option is selected to store the second date.
  handleSecondaryDateChange = (value) => {
    this.validateDate(value, 'toDate', 'VADOR');
    this.setState({ receiptDateSecondaryValue: value });
  }

  handleTaskCompletedSecondaryDateChange = (value) => {
    this.validateDate(value, 'toDate', 'FDATE');
    this.setState({ taskCompletedDateSecondaryValue: value });
  }

  handleApplyFilter = () => {
    if (this.state.receiptDateState === 0) {
      this.props.setSelectedValue(
        [
          this.state.receiptDateState,
          this.state.receiptDatePrimaryValue,
          this.state.receiptDateSecondaryValue
        ], 'vaDor');
    } else {
      this.props.setSelectedValue([this.state.receiptDateState, this.state.receiptDatePrimaryValue], 'vaDor');
    }
  }

  isApplyButtonEnabled = () => {

    if (this.state.dateErrorsFrom.length > 0 || this.state.dateErrorsTo.length > 0) {
      return true;
    }
    if (this.state.receiptDateState >= 1 && this.state.receiptDatePrimaryValue !== '') {
      return false;
    }

    if (this.state.receiptDateState === 0 &&
      this.state.receiptDatePrimaryValue.length > 0 &&
      this.state.receiptDateSecondaryValue.length > 0) {
      return false;
    }

    return true;
  }

  clearAllFilters = () => {
    this.setreceiptDateState(-1);
    this.setState({ receiptDatePrimaryValue: '' });
    this.setState({ receiptDateSecondaryValue: '' });
    this.setTaskCompletedDateState(-1);
    this.setState({ taskCompletedDatePrimaryValue: '' });
    this.setState({ taskCompletedDateSecondaryValue: '' });
    this.setState({ dateErrorsFrom: [] });
    this.setState({ dateErrorsTo: [] });
    this.props.clearFilters();

  }

  handleTaskCompletedApplyFilter = () => {
    if (this.state.taskCompletedDateState === 0) {
      this.props.setSelectedValue(
        [
          this.state.taskCompletedDateState,
          this.state.taskCompletedDatePrimaryValue,
          this.state.taskCompletedDateSecondaryValue
        ], 'completedDateColumn');
    } else {
      this.props.setSelectedValue([this.state.taskCompletedDateState, this.state.taskCompletedDatePrimaryValue],
        'completedDateColumn');
    }
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
        {this.props.isReceiptDateFilter && <ReceiptDatePicker
          handleDateChange={this.handleDateChange}
          handleSecondaryDateChange={this.handleSecondaryDateChange}
          setSelectedValue={this.props.setSelectedValue}
          handleApplyFilter={this.handleApplyFilter}
          onChangeMethod={this.setreceiptDateState}
          receiptDateState={this.state.receiptDateState}
          receiptDateValues={this.state.receiptDateValues}
          receiptDateFilterStates={receiptDateFilterStates}
          isApplyButtonEnabled={this.isApplyButtonEnabled()}
          dateErrorsFrom = {this.state.dateErrorsFrom}
          dateErrorsTo = {this.state.dateErrorsTo}
        />}
        {this.props.isTaskCompletedDateFilter && <TaskCompletedDatePicker
          handleTaskCompletedDateChange={this.handleTaskCompletedDateChange}
          handleTaskCompletedSecondaryDateChange={this.handleTaskCompletedSecondaryDateChange}
          setSelectedValue={this.props.setSelectedValue}
          handleTaskCompletedApplyFilter={this.handleTaskCompletedApplyFilter}
          onChangeMethod={this.setTaskCompletedDateState}
          taskCompletedDateState={this.state.taskCompletedDateState}
          taskCompletedDateValues={this.state.taskCompletedDateValues}
          taskCompletedDateFilterStates={taskCompletedDateFilterStates}
          dateErrorsFrom = {this.state.dateErrorsFrom}
          dateErrorsTo = {this.state.dateErrorsTo}
        />

        }
        {!(this.props.isReceiptDateFilter || this.props.isTaskCompletedDateFilter) &&
          React.cloneElement(React.Children.only(children), {
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
  setSelectedValue: PropTypes.func.isRequired,
  isReceiptDateFilter: PropTypes.bool,
  isTaskCompletedDateFilter: PropTypes.bool,
};

export default QueueDropdownFilter;
