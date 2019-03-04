import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import {
  requestPatch
} from '../uiReducer/uiActions';
import editModalBase from './EditModalBase';
import { taskActionData } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES.json';

import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../components/DataDropdowns';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';

import { TIME_OPTIONS } from '../../hearings/constants/constants';
import { css } from 'glamor';

const formStyling = css({
  '& .cf-form-radio-option:not(:last-child)': {
    display: 'inline-block',
    marginRight: '25px'
  },
  marginBottom: 0
});

class HearingTime extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isOther: false
    };
  }

  getTimeOptions = () => {
    const { selectedRegionalOffice } = this.props;

    if (selectedRegionalOffice === 'C') {
      return [
        { displayText: '9:00 am',
          value: '9:00' },
        { displayText: '1:00 pm',
          value: '13:00' },
        { displayText: 'Other',
          value: 'other' }
      ];
    }

    return [
      { displayText: '8:30 am',
        value: '8:30' },
      { displayText: '12:30 pm',
        value: '12:30' },
      { displayText: 'Other',
        value: 'other' }
    ];
  }

  onRadioChange = (value) => {
    if (value === 'other') {
      this.setState({ isOther: true });
      this.props.onChange(null);
    } else {
      this.setState({ isOther: false });
      this.props.onChange(value);
    }
  }

  render() {
    const { errorMessage, value } = this.props;

    return (
      <React.Fragment>
        <span {...formStyling}>
          <RadioField
            errorMessage={errorMessage}
            name="time"
            label="Time"
            strongLabel
            options={this.getTimeOptions()}
            onChange={this.onRadioChange}
            value={this.state.isOther ? 'other' : value} />
        </span>
        {this.state.isOther && <SearchableDropdown
          name="optionalTime"
          placeholder="Select a time"
          options={TIME_OPTIONS}
          value={value}
          onChange={this.props.onChange}
          hideLabel />}
      </React.Fragment>
    );
  }
}

class ScheduleLater extends React.Component {
  constructor (props) {
    super(props);

    this.state = {
      regionalOffice: props.initialRegionalOffice || ''
    };
  }

  render() {

    const {
      initialHearingDate, initialHearingTime
      onNewHearingChange, appeal,
      newHearing: { hearingTime, hearingDayId, hearingLocation }
    } = this.props;

    return (
      <div>
        <RegionalOfficeDropdown
          value={this.state.regionalOffice}
          onChange={(value) => this.setState({ regionalOffice: value })}
          validateValueOnMount
        />
        <AppealHearingLocationsDropdown
          appealId={appeal.externalId}
          value={hearingLocation}
          onChange={(value) => onNewHearingChange('hearingLocation', value)}
        />
        <HearingDateDropdown
          value={hearingDayId}
          onChange={(value) => onNewHearingChange('hearingDayId', value)}
        />
        {hearingDayId &&
          <HearingTime
            regionalOffice={this.state.regionalOffice}
            value={hearingTime}
            onChange={(value) => onNewHearingChange('hearingTime', value)}
          />}
      </div>
    );
  }
}

class PostponeHearingModal extends React.Component {
  getReschedulePayload = () => {
    const { newHearing: { hearingTime, hearingDayId, hearingLocation } } = this.props.reschedule;

    return {
      action: 'reschedule',
      new_hearing_attrs: {
        hearing_time: hearingTime,
        hearing_pkseq: hearingDayId,
        hearing_location: hearingLocation
      }
    };
  }

  getScheduleLaterPayload = () => {
    const { withAdminActionKlass, adminActionInstructions } = this.props.scheduleLater;

    return {
      action: 'schedule_later',
      with_admin_action_klass: withAdminActionKlass,
      admin_action_instructions: adminActionInstructions
    };
  }

  getAfterDispositionUpdate = () => {
    const { scheduleLater } = this.props;

    if (scheduleLater) {
      return this.getReschedulePayload();
    }

    return this.getScheduleLaterPayload();
  }

  payload = () => {
    return {
      data: {
        task: {
          status: TASK_STATUSES.cancelled,
          business_payloads: {
            values: {
              disposition: 'postponed',
              after_disposition_update: this.getAfterDispositionUpdatePayload()
            }
          }
        }
      }
    };
  }

  submit = () => {
    const {
      task,
      hearingDay
    } = this.props;
    const payload = {
      data: {
        task: {
          status: TASK_STATUSES.cancelled
        }
      }
    };
    const hearingScheduleLink = taskActionData(this.props).back_to_hearing_schedule ?
      <p>
        <Link href={`/hearings/schedule/assign?roValue=${hearingDay.regionalOffice}`}>Back to Hearing Schedule </Link>
      </p> : null;
    const successMsg = {
      title: taskActionData(this.props).message_title,
      detail: <span><span>{taskActionData(this.props).message_detail}</span>{hearingScheduleLink}</span>
    };

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      });
  }

  render = () => {
    const taskData = taskActionData(this.props);

    return <div>{taskData && taskData.modal_body}</div>;
  };
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  hearingDay: state.ui.hearingDay
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks
}, dispatch);

const propsToText = (props) => {
  const taskData = taskActionData(props);
  const pathAfterSubmit = (taskData && taskData.redirect_after) || '/queue';

  return {
    title: taskData ? taskData.modal_title : '',
    pathAfterSubmit
  };
};

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    PostponeHearingModal, { propsToText }
  ))
));
