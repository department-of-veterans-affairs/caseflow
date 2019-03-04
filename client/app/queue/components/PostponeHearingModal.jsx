import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import moment from 'moment';
// import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import TextareaField from '../../components/TextareaField';

import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import {
  requestPatch, onAssignHearingChange,
  onScheduleHearingLaterChange
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
    const { regionalOffice } = this.props;

    if (regionalOffice === 'C') {
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

class AssignHearing extends React.Component {

  /*
    This duplicates a lot of the logic from AssignHearingModal.jsx
    TODO: refactor so both of these modals use the same components
  */
  constructor (props) {
    super(props);

    const { initialRegionalOffice, initialHearingDate, initialHearingTime } = props;

    this.state = {
      regionalOffice: initialRegionalOffice || null,
      hearingLocation: null,
      hearingTime: initialHearingTime || null,
      hearingDay: initialHearingDate || null
    };
  }

  afterStateChange = () => {
    this.props.onChange(this.state);
  }

  onRegionalOfficeChange = (regionalOffice) => {
    this.setState({
      regionalOffice,
      hearingLocation: null,
      hearingTime: null,
      hearingDay: null
    });
  }

  onChange = (key, value) => {
    this.setState(
      { [key]: value },
      this.afterStateChange
    );
  }

  render() {

    const { appeal } = this.props;
    const { regionalOffice, hearingLocation, hearingDay, hearingTime } = this.state;

    return (
      <div>
        <RegionalOfficeDropdown
          value={regionalOffice}
          onChange={this.onRegionalOfficeChange}
          validateValueOnMount
        />
        {regionalOffice && <React.Fragment>
          <AppealHearingLocationsDropdown
            key={`hearingLocation__${regionalOffice}`}
            regionalOffice={regionalOffice}
            appealId={appeal.externalId}
            value={hearingLocation}
            onChange={(value) => this.onChange('hearingLocation', value)}
          />
          <HearingDateDropdown
            key={`hearingDate__${regionalOffice}`}
            regionalOffice={regionalOffice}
            value={hearingDay}
            onChange={(value) => this.onChange('hearingDay', value)}
            validateValueOnMount
          />
          <HearingTime
            key={`hearingTime__${regionalOffice}`}
            regionalOffice={regionalOffice}
            value={hearingTime}
            onChange={(value) => this.onChange('hearingTime', value)}
          />
        </React.Fragment>}
      </div>
    );
  }
}

const ScheduleLaterWithAdminAction = ({ reasons, value, set }) => (
  <div>
    <SearchableDropdown
      label="Select Reason"
      strongLabel
      name="postponementReason"
      options={reasons}
      value={value ? value.withAdminActionKlass : null}
      onChange={(val) => set('withAdminActionKlass', val)}
    />
    <TextareaField
      label="Instructions"
      strongLabel
      name="adminActionInstructions"
      value={value ? value.adminActionInstructions : ''}
      onChange={(val) => set('adminActionInstructions', val)}
    />
  </div>
);

class PostponeHearingModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      afterDispositionUpdateAction: '',
      afterDispositionUpdateActionOptions: [
        {
          displayText: 'Reschedule immediately',
          value: 'reschedule'
        },
        {
          displayText: 'Send to Schedule Veteran list',
          value: 'schedule_later'
        },
        {
          displayText: 'Apply admin action',
          value: 'schedule_later_with_admin_action'
        }
      ]
    };
  }

  getAssignHearingTime = (time, day) => {

    return {
      // eslint-disable-next-line id-length
      h: time.split(':')[0],
      // eslint-disable-next-line id-length
      m: time.split(':')[1],
      offset: moment.tz(day.hearingDate, day.timezone || 'America/New_York').format('Z')
    };
  }

  getReschedulePayload = () => {
    const { assignHearing: { hearingTime, hearingDay, hearingLocation } } = this.props;

    return {
      action: 'reschedule',
      new_hearing_attrs: {
        hearing_time: this.getAssignHearingTime(hearingTime, hearingDay),
        hearing_pkseq: hearingDay.hearingId,
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

  getAfterDispositionUpdatePayload = () => {
    const { afterDispositionUpdateAction } = this.state;

    if (afterDispositionUpdateAction.value === 'reschedule') {
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

  onAssignHearingChange = (assignHearingAttrs) => {
    const { hearingLocation, hearingDay, hearingTime } = assignHearingAttrs;

    this.props.onAssignHearingChange({
      hearingLocation,
      hearingDay,
      hearingTime
    });
  }

  onScheduleLaterChange = (key, value) => {
    this.props.onScheduleHearingLaterChange({ [key]: value });
  }

  submit = () => {
    const { task } = this.props;
    const payload = this.payload();
    const successMsg = {
      title: taskActionData(this.props).message_title
    };

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      });
  }

  render = () => {
    const { appeal, scheduleLater } = this.props;
    const { afterDispositionUpdateAction } = this.state;
    const adminActionOptions = taskActionData(this.props).options;

    return (
      <div>
        <RadioField
          name="postponeAfterDispositionUpdateAction"
          hideLabel
          strongLabel
          options={this.state.afterDispositionUpdateActionOptions}
          onChange={(option) => this.setState({ afterDispositionUpdateAction: option })}
          value={afterDispositionUpdateAction}
        />

        {afterDispositionUpdateAction === 'reschedule' &&
        <AssignHearing
          appeal={appeal}
          onChange={this.onAssignHearingChange}
        />
        }{afterDispositionUpdateAction === 'schedule_later_with_admin_action' &&
        <ScheduleLaterWithAdminAction
          reasons={adminActionOptions}
          value={scheduleLater}
          set={this.onScheduleLaterChange}
        />
        }
      </div>
    );
  };
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  hearingDay: state.ui.hearingDay,
  scheduleLater: state.ui.scheduleHearingLater,
  assighHearing: state.ui.assignHearing,
  adminActionOptions: taskActionData(ownProps).options
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks,
  onAssignHearingChange,
  onScheduleHearingLaterChange
}, dispatch);

const propsToText = (props) => {
  const taskData = taskActionData(props);

  const pathAfterSubmit = (taskData && taskData.redirect_after) || '/queue';

  return {
    title: 'Postpone Hearing',
    pathAfterSubmit
  };
};

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    PostponeHearingModal, { propsToText }
  ))
));
