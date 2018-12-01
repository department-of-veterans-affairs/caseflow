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
import { onRegionalOfficeChange, onHearingDateChange, onHearingTimeChange } from '../../components/common/actions';
import { fullWidth } from '../constants';
import editModalBase from './EditModalBase';
import { formatDateStringForApi, formatDateStr } from '../../util/DateUtil';

import type {
  State
} from '../types/state';

import { withRouter } from 'react-router-dom';
import RadioField from '../../components/RadioField';
import RoSelectorDropdown from '../../components/RoSelectorDropdown';
import HearingDateDropdown from '../../components/HearingDateDropdown';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import {
  taskById,
  appealWithDetailSelector
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
|};

type Props = Params & {|
  // From state
  savePending: boolean,
  selectedRegionalOffice: string,
  history: Object,
  hearingDay: Object,
  selectedHearingDate: string,
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
  onHearingDateChange: typeof onHearingDateChange,
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
    } else if (hearingDay.regionalOffice.value) {
      return hearingDay.regionalOffice;
    } else if (appeal.regionalOffice) {
      return appeal.regionalOffice.key;
    }

    return '';
  }

  componentWillMount = () => {
    const { hearingDay } = this.props;

    this.props.onRegionalOfficeChange(this.getRO());

    if (hearingDay.hearingDate) {
      this.props.onHearingDateChange(hearingDay.hearingDate);
      this.props.onHearingTimeChange(hearingDay.hearingTime);
    }
  };

  formatDateString = (dateToFormat) => {
    const formattedDate = formatDateStr(dateToFormat);

    return formatDateStringForApi(formattedDate);
  };

  formatHearingDate = () => {
    const { selectedHearingDate, selectedHearingTime } = this.props;

    if (!selectedHearingTime || !selectedHearingDate) {
      return null;
    }

    const dateParts = selectedHearingDate.split('-');
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

  validateForm = () => {

    const hearingDate = this.formatHearingDate();

    if (hearingDate === null) {

      this.props.showErrorMessage({
        title: 'Required Fields',
        detail: 'Please fill in Date of Hearing and Time fields'
      });

      return false;
    }

    return true;
  }

  submit = () => {
    const { task, appeal, selectedHearingDate, selectedRegionalOffice } = this.props;
    const values = {
      regional_office_value: selectedRegionalOffice.value,
      hearing_pkseq: task.taskBusinessPayloads[0].values.hearing_pkseq,
      hearing_type: task.taskBusinessPayloads[0].values.hearing_type,
      hearing_date: this.formatHearingDate()
    };

    const payload = {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values
          }
        }
      }
    };

    const getRegionalLink = () => {
      let requestUrl;

      if (this.props.selectedRegionalOffice) {
        requestUrl = `roLabel=${selectedRegionalOffice.label}&roValue=${selectedRegionalOffice.value}`;
      }

      return requestUrl;
    };

    const hearingType = this.props.task.taskBusinessPayloads[0].values.hearing_type ===
                          CENTRAL_OFFICE_HEARING ? 'CO' : VIDEO_HEARING;
    const hearingDateStr = formatDateStr(selectedHearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');
    const title = `You have successfully assigned ${appeal.veteranFullName} to a ${hearingType} hearing ` +
                  `on ${hearingDateStr}.`;

    const getDetail = () => {
      return <p>To assign another veteran please use the "Schedule Veterans" link below.
      You can also use the hearings section below to view the hearing in new tab.<br /><br />
        <Link href={`/hearings/schedule/assign?${getRegionalLink()}`}>Back to Schedule Veterans</Link></p>;
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
    const { selectedHearingTime } = this.props;
    const timeOptions = this.getTimeOptions();

    if (!selectedHearingTime) {
      return {};
    }

    return _.find(timeOptions, (option) => option.value === selectedHearingTime);
  }

  render = () => {
    const {
      selectedHearingDate, selectedRegionalOffice,
      selectedHearingTime
    } = this.props;

    const timeOptions = this.getTimeOptions();

    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <RoSelectorDropdown
          onChange={(opt) => {
            this.props.onRegionalOfficeChange(opt);
          }}
          value={selectedRegionalOffice || {}}
          readOnly
          changePrompt
          staticOptions={centralOfficeStaticEntry} />

        {selectedRegionalOffice && <HearingDateDropdown
          key={selectedRegionalOffice}
          regionalOffice={selectedRegionalOffice}
          onChange={(opt) => {
            this.props.onHearingDateChange(opt.value);
          }}
          value={selectedHearingDate}
          readOnly={false}
          changePrompt
        />}

        <RadioField
          name="time"
          label="Time"
          strongLabel
          options={timeOptions}
          onChange={this.props.onHearingTimeChange}
          value={selectedHearingTime} />
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
  hearingDay: state.ui.hearingDay,
  selectedHearingDate: state.components.selectedHearingDate,
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
  onHearingDateChange,
  onHearingTimeChange
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    AssignHearingModal, { title: 'Schedule Veteran',
      button: 'Schedule' }
  ))
): React.ComponentType<Params>);
