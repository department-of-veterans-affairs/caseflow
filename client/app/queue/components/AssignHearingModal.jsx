// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  resetSaveState,
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch
} from '../uiReducer/uiActions';
import { onRegionalOfficeChange } from '../../components/common/actions';
import { fullWidth } from '../constants';
import editModalBase from './EditModalBase';
import { getTime, formatDate, formatDateStringForApi, formatDateStr } from '../../util/DateUtil';

import type {
  State
} from '../types/state';

import { withRouter } from 'react-router-dom';
import RadioField from '../../components/RadioField';
import Button from '../../components/Button';
import InlineForm from '../../components/InlineForm';
import RoSelectorDropdown from '../../components/RoSelectorDropdown';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import DateSelector from '../../components/DateSelector';
import _ from 'lodash';
import type { Appeal, Task } from '../types/models';
import { CENTRAL_OFFICE_HEARING, VIDEO_HEARING } from '../../hearings/constants/constants';

type Params = {|
  task: Task,
  taskId: string,
  appeal: Appeal,
  appealId: string,
|};

type Props = Params & {|
  // From state
  savePending: boolean,
  selectedRegionalOffice: Object,
  history: Object,
  // Action creators
  showErrorMessage: typeof showErrorMessage,
  resetErrorMessages: typeof resetErrorMessages,
  showSuccessMessage: typeof showSuccessMessage,
  resetSuccessMessages: typeof resetSuccessMessages,
  resetSaveState: typeof resetSaveState,
  onRegionalOfficeChange: typeof onRegionalOfficeChange,
  requestPatch: typeof requestPatch,
  onReceiveAmaTasks: typeof onReceiveAmaTasks
|};

type LocalState = {|
  selectedDate: '',
  selectedTime: string,
  dateEdit: boolean
|}

const buttonLinksStyling = css({
  marginRight: '30px',
  width: '150px'
});

const titleStyling = css({
  marginBottom: 0,
  padding: 0
});

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

class AssignHearingModal extends React.PureComponent<Props, LocalState> {
  constructor(props) {
    super(props);

    this.state = {
      selectedDate: props.hearingDay.hearingDate || '',
      selectedTime: '',
      dateEdit: false,
      timeOptions: props.task.taskBusinessPayloads[0].values.hearing_type === VIDEO_HEARING ?
        [{ displayText: '8:30 am',
          value: '8:30 am ET' }, { displayText: '12:30 pm',
          value: '12:30 pm ET' }] :
        [{ displayText: '9:00 am',
          value: '9:00 am ET' }, { displayText: '1:00 pm',
          value: '1:00 pm ET' }]
    };
  }

  componentWillMount = () => {
    const ro = this.props.hearingDay.regionalOffice || this.props.task.taskBusinessPayloads[0].values.regional_office_value;
    this.props.onRegionalOfficeChange(ro);
  };

  onDateClick = () => {
    this.setState({ dateEdit: true });
    this.setState({ selectedDate: this.formatDateString(this.props.task.taskBusinessPayloads[0].values.hearing_date) });
  };

  formatDateString = (dateToFormat) => {
    const formattedDate = formatDate(dateToFormat);

    return formatDateStringForApi(formattedDate);
  };

  formatHearingDate = () => {
    const dateParts = this.state.selectedDate.split('-');
    const year = parseInt(dateParts[0], 10);
    const month = parseInt(dateParts[1], 10) - 1;
    const day = parseInt(dateParts[2], 10);
    const timeParts = this.state.selectedTime.split(':');
    let hour = parseInt(timeParts[0], 10);

    if (hour === 1) {
      hour += 12;
    }
    const minute = parseInt(timeParts[1].split(' ')[0], 10);
    const hearingDate = new Date(year, month, day, hour, minute);

    return hearingDate;
  };

  getRegionalOffice = (regionalOffice) => {
    return regionalOffice.value ? regionalOffice.value : regionalOffice;
  };

  submit = () => {
    const {
      task,
      appeal
    } = this.props;

    const payload = {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values: {
              regional_office_value: this.getRegionalOffice(this.props.selectedRegionalOffice),
              hearing_pkseq: this.props.task.taskBusinessPayloads[0].values.hearing_pkseq,
              hearing_type: this.props.task.taskBusinessPayloads[0].values.hearing_type,
              hearing_date: this.formatHearingDate()
            }
          }
        }
      }
    };

    const hearingType = this.props.task.taskBusinessPayloads[0].values.hearing_type ===
                          CENTRAL_OFFICE_HEARING ? 'CO' : VIDEO_HEARING;
    const hearingDateStr = formatDateStr(this.state.selectedDate, 'YYYY-MM-DD', 'MM/DD/YYYY');
    const title = `You have successfully assigned ${appeal.veteranFullName} to a ${hearingType} hearing ` +
                  `on ${hearingDateStr}.`;

    const getDetail = () => {
      return <p>To assign another veteran please use the "Schedule Veterans" link below.
      You can also use the hearings section below to view the hearing in new tab.<br /><br />
        <Link href="/hearings/schedule/assign">Back to Schedule Veterans</Link></p>;
    };

    const successMsg = { title,
      detail: getDetail() };

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        // Review with team to see why this is failing.
        this.props.onReceiveAmaTasks(response.tasks.data);
        this.props.history.goBack();
      }, () => {
        this.props.showErrorMessage({
          title: 'No Available Slots',
          detail: 'Could not find any available slots for this regional office and hearing day combination.' +
              ' Please select a different date.'
        });
      });
  };

  getSelectedTimeOption = () => {
    const { task } = this.props;
    const { timeOptions } = this.state;

    const timeStr = getTime(task.taskBusinessPayloads[0].values.hearing_date);
    return _.find(timeOptions, (option) => option.value === timeStr);
  }

  render = () => {
    const { selectedDate, timeOptions } = this.state;
    const { selectedRegionalOffice, task, onRegionalOfficeChange } = this.props;

    if (!task) {
      return null;
    }

    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <b {...titleStyling} >Regional Office</b>

        <RoSelectorDropdown
          onChange={onRegionalOfficeChange}
          value={selectedRegionalOffice}
          readOnly={true}
          changePrompt={true}
          staticOptions={centralOfficeStaticEntry} />

        <b {...titleStyling} >Date of hearing</b>
        {/*this.state.dateEdit &&
          <DateSelector
            name="hearingDate"
            label={false}
            value={selectedDate}
            onChange={(option) => option && this.setState({ selectedDate: option })}
            type="date"
          />
        */}
        {!this.state.dateEdit &&
          <InlineForm>
            <p {...buttonLinksStyling}>{formatDateStr(selectedDate)}</p>
            <Button
              name="Change"
              linkStyling
              onClick={this.onDateClick} />
          </InlineForm>
        }
        <RadioField
          name="time"
          label="Time"
          strongLabel
          options={timeOptions}
          onChange={(option) => option && this.setState({ selectedTime: option })}
          value={this.getSelectedTimeOption().value} />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOfficeOptions: state.components.regionalOffices,
  hearingDay: state.ui.hearingDay
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showErrorMessage,
  resetErrorMessages,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch,
  onReceiveAmaTasks,
  onRegionalOfficeChange
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    AssignHearingModal, { title: 'Schedule Veteran',
      button: 'Schedule' }
  ))
): React.ComponentType<Params>);
