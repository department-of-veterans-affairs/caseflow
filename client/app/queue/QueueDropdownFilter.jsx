import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { css } from 'glamor';
import { startCase } from 'lodash';
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
      taskCompletedDateSecondaryValue: ''
    };
  }

  setreceiptDateState = (value) => {
    this.setState({ receiptDateState: value.value });
  };

  setTaskCompletedDateState = (value) => {
    this.setState({ taskCompletedDateState: value.value });
  };

  handleDateChange = (value) => {
    this.setState({ receiptDatePrimaryValue: value });
  }

  handleTaskCompletedDateChange = (value) => {
    this.setState({ taskCompletedDatePrimaryValue: value });
  }

  // Used when the between dates option is selected to store the second date.
  handleSecondaryDateChange = (value) => {
    this.setState({ receiptDateSecondaryValue: value });
  }

  handleTaskCompletedSecondaryDateChange = (value) => {
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
    const { children, name } = this.props;

    // Some of the filter names are camelCase, which would be displayed to the user.
    // To make this more readable, convert the camelCase text to title case.
    const displayName = startCase(name);

    const rel = {
      position: 'relative'
    };

    return <div style={rel}>
      <div className="cf-dropdown-filter" style={{ top: '10px' }} ref={(rootElem) => {
        this.rootElem = rootElem;
      }}>
        {this.props.addClearFiltersRow &&
          <div className="cf-filter-option-row" onClick={this.clearAllFilters}>
            <button className="cf-text-button"
              disabled={!this.props.isClearEnabled}>
              <div className="cf-clear-filter-button-wrapper">
                Clear {displayName} filter
              </div>
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
  isReceiptDateFilter: PropTypes.func.isRequired,
  isTaskCompletedDateFilter: PropTypes.func.isRequired
};

export default QueueDropdownFilter;
