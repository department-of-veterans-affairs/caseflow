import React from 'react';
import PropTypes from 'prop-types';
import ReactSelectDropdown from '../../../client/app/components/ReactSelectDropdown';
import DateSelector from './DateSelector';
import Button from './Button';
import { css } from 'glamor';

const dateDropdownMap = [
  { value: 0, label: 'Between these dates' },
  { value: 1, label: 'Before this date' },
  { value: 2, label: 'After this date' },
  { value: 3, label: 'On this date' }
];

const receiptDatePicker = (props) => {

  const errorMessagesNode = (errors, errType) => {
    if (errors.length) {
      return (
        errors.map((error, index) =>
          (errType === error.key) &&
            <p id={`${errType}Err${index}`} key={index}
              style={{ color: 'red', fontSize: '13px', fontWeight: '900', marginBottom: '0px' }}>
              {error.message}
            </p>
        )
      );
    }
  };

  const styles = {
    optSelect: css({
      '.receiptDate': {
      },
      '& .css-yk16xz-control': {
        borderRadius: '0px'
      },
      '& .css-1pahdxg-control': {
        borderColor: 'hsl(0, 0%, 100%)',
        boxShadow: '0 0 0 1px #5B616B !important',
        borderRadius: '0px !important',
        ':hover': {
          borderColor: 'hsl(0, 0%, 80%)',
        }
      }
    })
  };

  const selectContainerStyles = css({
    '& .data-css-1co2jut': {
      margin: '0 5% 0 5%'
    },
    '& .cf-form-textinput.usa-input-error': {
      borderLeft: '4px solid #cd2026',
      marginTop: '0px',
      paddingBottom: '0px',
      paddingLeft: '0.5rem',
      paddingTop: '0px',
      position: 'relative',
      right: '2px'
    },
    '& .usa-input-error input': {
      width: 'inherit'
    },
    '& .cf-form-textinput': {
      paddingTop: '6.2% !important',
      marginBottom: 0,
      '& .input-container': {
        '& input': {
          margin: 0,
          height: '37.5px'
        }
      }
    }
  });

  const getDatePickerElements = () => {
    const receiptDateFilterStates = props.receiptDateFilterStates;
    const dateErrorsFrom = props.dateErrorsFrom;
    const dateErrorsTo = props.dateErrorsTo;

    switch (props.receiptDateState) {
    case receiptDateFilterStates.BETWEEN: return (
      <div style={{ margin: '0 5%' }}>
        <DateSelector
          onChange={props.handleDateChange}
          label="From"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')}
        />
        <DateSelector
          onChange={props.handleSecondaryDateChange}
          label="To"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsTo, 'toDate')}
        />
      </div>);
    case receiptDateFilterStates.BEFORE: return (
      <div style={{ margin: '0 5%' }}>
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          label = "Receipt date"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')}
        />
      </div>
    );
    case receiptDateFilterStates.AFTER: return (
      <div style={{ margin: '0 5%' }}>
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          label = "Receipt date"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')}
        />
      </div>
    );
    case receiptDateFilterStates.ON: return (
      <div style={{ margin: '0 5%' }}>
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          label = "Receipt date"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')}
        />
      </div>
    );

    default:
    }
  };

  return <div id="dropdown" {...selectContainerStyles}>
    <div style={{ marginLeft: '5%', marginRight: '5%', marginTop: '2.7%' }}>
      <ReactSelectDropdown
        className = {`receiptDate ${styles.optSelect}`}
        label="Date filter parameters"
        options={dateDropdownMap}
        onChangeMethod={props.onChangeMethod}
      />
    </div>
    <div style={{ width: '100%', margin: 'auto', paddingBottom: '12.7%' }}>
      {getDatePickerElements()}
    </div>

    <div style={{ display: 'flex',
      padding: '16px 10px 24px 0',
      justifyContent: 'right',
      width: '190px',
      borderTop: '1px solid #d6d7d9' }}>
      <Button disabled={props.isApplyButtonEnabled} onClick={props.handleApplyFilter}>
        <span>Apply Filter</span>
      </Button>
    </div>

  </div>;
};

receiptDatePicker.propTypes = {
  receiptDateFilterStates: PropTypes.object,
  receiptDateState: PropTypes.number,
  handleApplyFilter: PropTypes.func.isRequired,
  handleDateChange: PropTypes.func.isRequired,
  handleSecondaryDateChange: PropTypes.func.isRequired,
  isApplyButtonEnabled: PropTypes.bool.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      value: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      displayText: PropTypes.string,
    })
  ),
  defaultValue: PropTypes.object,
  label: PropTypes.string,
  onChangeMethod: PropTypes.func,
  className: PropTypes.string,
  disabled: PropTypes.bool,
  customPlaceholder: PropTypes.string,
  dateErrorsFrom: PropTypes.array,
  dateErrorsTo: PropTypes.array
};

export default receiptDatePicker;
