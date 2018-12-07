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
import { onRegionalOfficeChange, onHearingDayChange, onHearingTimeChange } from '../../components/common/actions';
import { fullWidth } from '../constants';
import editModalBase from './EditModalBase';
import { formatDateStringForApi, formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';

import type {
  State
} from '../types/state';

import { withRouter } from 'react-router-dom';
import RadioField from '../../components/RadioField';
import RoSelectorDropdown from '../../components/RoSelectorDropdown';
import HearingDayDropdown from '../../components/HearingDayDropdown';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import {
  appealWithDetailSelector,
  actionableTasksForAppeal
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import _ from 'lodash';
import type { Appeal, Task } from '../types/models';
import { CENTRAL_OFFICE_HEARING, VIDEO_HEARING } from '../../hearings/constants/constants';

type Params = {|
  task: Task,
  taskId: string,
  appeal: Appeal,
  appealId: string,
  userId: string
|};

type Props = Params & {|
  // From state
  savePending: boolean,
  selectedRegionalOffice: Object,
  scheduleHearingTask: Object,
  history: Object,
  hearingDay: Object,
  selectedHearingDay: Object,
  selectedHearingTime: string,
  // Action creators
  showErrorMessage: typeof showErrorMessage,
  resetErrorMessages: typeof resetErrorMessages,
  showSuccessMessage: typeof showSuccessMessage,
  resetSuccessMessages: typeof resetSuccessMessages,
  resetSaveState: typeof resetSaveState,
  onRegionalOfficeChange: typeof onRegionalOfficeChange,
  requestPatch: typeof requestPatch,
  onReceiveAmaTasks: typeof onReceiveAmaTasks,
  onHearingDayChange: typeof onHearingDayChange,
  onHearingTimeChange: typeof onHearingTimeChange
|};

type LocalState = {|
  timeOptions: Array<Object>
|}

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

class AssignHearingModal extends React.PureComponent<Props, LocalState> {

  componentDidMount = () => {
    const { hearingDay } = this.props;

    if (hearingDay.hearingTime) {
      this.props.onHearingTimeChange(hearingDay.hearingTime);
    }

    this.addScheduleHearingTask();
  }

  submit = () => {
    return this.completeScheduleHearingTask();
  };

  validateForm = () => {
    const hearingDate = this.formatHearingDate();

    if (hearingDate === null || this.props.selectedHearingTime === null) {

      this.props.showErrorMessage({
        title: 'Required Fields',
        detail: 'Please fill in Date of Hearing and Time fields'
      });

      return false;
    }

    return true;
  }

  addScheduleHearingTask = () => {
    const {
      scheduleHearingTask, appeal, userId
    } = this.props;

    if (!scheduleHearingTask) {
      const payload = {
        data: {
          tasks: [
            {
              type: 'ScheduleHearingTask',
              external_id: appeal.externalId,
              assigned_to_type: 'User',
              assigned_to_id: userId
            }
          ]
        }
      };

      return ApiUtil.post('/tasks', payload).then((response) => {
        const resp = JSON.parse(response.text);

        this.props.onReceiveAmaTasks(resp.tasks.data);
      });
    }
  }

  completeScheduleHearingTask = () => {

    const {
      scheduleHearingTask, history,
      selectedHearingDay, selectedRegionalOffice
    } = this.props;

    const payload = {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values: {
              regional_office_value: selectedRegionalOffice.value,
              hearing_pkseq: selectedHearingDay.value.hearingId,
              hearing_type: this.getHearingType(),
              hearing_date: this.formatHearingDate()
            }
          }
        }
      }
    };

    return this.props.requestPatch(`/tasks/${scheduleHearingTask.taskId}`, payload, this.getSuccessMsg()).
      then(() => {

        history.goBack();
      }, () => {
        this.props.showErrorMessage({
          title: 'No Available Slots',
          detail: 'Could not find any available slots for this regional office and hearing day combination. ' +
                  'Please select a different date.'
        });
      });
  }

  getTimeOptions = () => {
    const { appeal: { sanitizedHearingRequestType } } = this.props;

    if (sanitizedHearingRequestType === 'video') {
      return [
        { displayText: '8:30 am',
          value: '8:30 am ET' },
        { displayText: '12:30 pm',
          value: '12:30 pm ET' }
      ];
    }

    return [
      { displayText: '9:00 am',
        value: '9:00 am ET' },
      { displayText: '1:00 pm',
        value: '1:00 pm ET' }
    ];

  }

  getRO = () => {
    const { appeal, hearingDay } = this.props;
    const { sanitizedHearingRequestType } = appeal;

    if (sanitizedHearingRequestType === 'central_office') {
      return 'C';
    } else if (hearingDay.regionalOffice) {
      return hearingDay.regionalOffice;
    } else if (appeal.regionalOffice) {
      return appeal.regionalOffice.key;
    }

    return '';
  }

  getHearingType = () => {
    const { appeal: { sanitizedHearingRequestType } } = this.props;

    return sanitizedHearingRequestType === 'central_office' ? CENTRAL_OFFICE_HEARING : VIDEO_HEARING;
  }

  getSuccessMsg = () => {
    const { appeal, selectedHearingDay, selectedRegionalOffice } = this.props;

    const hearingDateStr = formatDateStr(selectedHearingDay.value.hearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');
    const title = `You have successfully assigned ${appeal.veteranFullName} ` +
                  `to a ${this.getHearingType()} hearing on ${hearingDateStr}.`;
    const href = `/hearings/schedule/assign?roValue=${selectedRegionalOffice.value}`;

    const detail = (
      <p>
        To assign another veteran please use the "Schedule Veterans" link below.
        You can also use the hearings section below to view the hearing in new tab.<br /><br />
        <Link href={href}>Back to Schedule Veterans</Link>
      </p>
    );

    return { title,
      detail };
  }

  formatDateString = (dateToFormat) => {
    const formattedDate = formatDateStr(dateToFormat);

    return formatDateStringForApi(formattedDate);
  };

  formatHearingDate = () => {
    const { selectedHearingDay, selectedHearingTime } = this.props;

    if (!selectedHearingTime || !selectedHearingDay) {
      return null;
    }

    const dateParts = selectedHearingDay.value.hearingDate.split('-');
    const year = parseInt(dateParts[0], 10);
    const month = parseInt(dateParts[1], 10) - 1;
    const day = parseInt(dateParts[2], 10);
    const timeParts = selectedHearingTime.split(':');
    let hour = parseInt(timeParts[0], 10);

    if (hour === 1) {
      hour += 12;
    }
    const minute = parseInt(timeParts[1].split(' ')[0], 10);
    const hearingDate = new Date(year, month, day, hour, minute);

    return hearingDate;
  };

  getSelectedTimeOption = () => {
    const { selectedHearingTime } = this.props;
    const timeOptions = this.getTimeOptions();

    if (!selectedHearingTime) {

      return {};
    }

    return _.find(timeOptions, (option) => option.value === selectedHearingTime);
  }

  getInitialValues = () => {
    const { hearingDay } = this.props;

    return {
      hearingTime: hearingDay.hearingTime,
      hearingDate: hearingDay.hearingDate,
      regionalOffice: this.getRO()
    };
  }

  render = () => {
    const {
      selectedHearingDay, selectedRegionalOffice,
      selectedHearingTime
    } = this.props;

    const initVals = this.getInitialValues();
    const timeOptions = this.getTimeOptions();

    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <RoSelectorDropdown
          onChange={this.props.onRegionalOfficeChange}
          value={selectedRegionalOffice || initVals.regionalOffice}
          readOnly
          changePrompt
          staticOptions={centralOfficeStaticEntry} />

        {selectedRegionalOffice && <HearingDayDropdown
          key={selectedRegionalOffice.value}
          regionalOffice={selectedRegionalOffice.value}
          onChange={this.props.onHearingDayChange}
          value={selectedHearingDay || initVals.hearingDate}
          readOnly={false}
          changePrompt
        />}

        <RadioField
          name="time"
          label="Time"
          strongLabel
          options={timeOptions}
          onChange={this.props.onHearingTimeChange}
          value={selectedHearingTime || initVals.hearingTime} />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  scheduleHearingTask: _.find(
    actionableTasksForAppeal(state, { appealId: ownProps.appealId }),
    (task) => task.type === 'ScheduleHearingTask'
  ),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOfficeOptions: state.components.regionalOffices,
  hearingDay: state.ui.hearingDay,
  selectedHearingDay: state.components.selectedHearingDay,
  selectedHearingTime: state.components.selectedHearingTime
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showErrorMessage,
  resetErrorMessages,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch,
  onReceiveAmaTasks,
  onRegionalOfficeChange,
  onHearingDayChange,
  onHearingTimeChange
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    AssignHearingModal, { title: 'Schedule Veteran',
      button: 'Schedule' }
  ))
): React.ComponentType<Params>);
