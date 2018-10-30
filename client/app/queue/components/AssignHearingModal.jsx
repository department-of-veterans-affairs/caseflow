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
import { getTime, formatDate, formatDateStringForApi } from '../../util/DateUtil';

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
  tasksForAppealAssignedToUserSelector,
  incompleteOrganizationTasksByAssigneeIdSelector,
  appealWithDetailSelector
} from '../selectors';
import { setTaskAttrs } from '../QueueActions';
import { prepareTasksForStore } from '../utils';
import DateSelector from '../../components/DateSelector';
import _ from 'lodash';
import type { Appeal, Task } from '../types/models';

type Params = {|
  task: Task,
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
  setTaskAttrs: typeof setTaskAttrs
|};

type LocalState = {|
  selectedDate: '',
  selectedTime: string,
  roEdit: boolean,
  dateEdit: boolean
|}

const buttonLinksStyling = css({
  marginRight: '30px',
  width: '100px'
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
      selectedDate: '',
      selectedTime: '',
      roEdit: false,
      dateEdit: false
    };
  }

  componentWillMount = () => {
    this.props.onRegionalOfficeChange(this.props.task.taskBusinessPayloads[0].values[0]);
  };

  onROClick = () => {
    this.setState({ roEdit: true });
  };

  onDateClick = () => {
    this.setState({ dateEdit: true });
    const formattedDate = formatDate(this.props.task.taskBusinessPayloads[0].values[4]);

    this.setState({ selectedDate: formatDateStringForApi(formattedDate) });
  };

  submit = () => {

    const newDateTime = new Date(`${this.state.selectedDate} ${this.state.selectedTime}`);

    const {
      task,
      appeal
    } = this.props;
    const payload = {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update',
            values: [
              this.props.selectedRegionalOffice.value,
              this.props.selectedRegionalOffice.label,
              this.props.task.taskBusinessPayloads[0].values[2],
              this.props.task.taskBusinessPayloads[0].values[3],
              newDateTime
            ]
          }
        }
      }
    };

    const hearingType = this.props.task.taskBusinessPayloads[0].values[3] === 'Central' ? 'CO' : 'Video';
    const hearingDateStr = formatDate(this.props.task.taskBusinessPayloads[0].values[4]);
    const title = `You have successfully assigned ${appeal.veteranFullName} to a ${hearingType} hearing ` +
                  `on ${hearingDateStr}.`;

    const getDetail = () => {
      return <p>To assign another veteran please use the "Assign Hearings" link below.
      You can also use the hearings section below to view the hearing in new tab.<br /><br />
        <Link href="/hearings/schedule/assign">Back to Assign Hearings</Link></p>;
    };

    const successMsg = { title,
      detail: getDetail() };

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);
        const preparedTasks = prepareTasksForStore(response.tasks.data);

        // Review with team to see why this is failing.
        this.props.setTaskAttrs(task.uniqueId, preparedTasks[task.uniqueId]);
        this.props.history.goBack();
      });
  };

  render = () => {
    if (!this.props.task) return null;

    const hearingDateStr = formatDate(this.props.task.taskBusinessPayloads[0].values[4]);
    const timeStr = getTime(this.props.task.taskBusinessPayloads[0].values[4]);

    const timeOptions = this.props.task.taskBusinessPayloads[0].values[3] === 'Video' ?
      [{ displayText: '8:30 am',
        value: '8:30 am ET' }, { displayText: '12:30 pm',
        value: '12:30 pm ET' }] :
      [{ displayText: '9:00 am',
        value: '9:00 am ET' }, { displayText: '1:00 pm',
        value: '1:00 pm ET' }];
    const selectedTime = _.find(timeOptions, (option) => option.value === timeStr);

    if (selectedTime && this.state.selectedTime === '') {
      this.setState({ selectedTime: selectedTime.value });
    }

    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <b {...titleStyling} >Regional Office</b>
        {this.state.roEdit &&
          <RoSelectorDropdown
            onChange={this.props.onRegionalOfficeChange}
            value={this.props.selectedRegionalOffice}
            staticOptions={centralOfficeStaticEntry} />
        }
        {!this.state.roEdit &&
              <InlineForm>
                <p {...buttonLinksStyling}> {this.props.task.taskBusinessPayloads[0].values[1]} </p>
                <Button
                  name="Change"
                  linkStyling
                  onClick={this.onROClick} />
              </InlineForm>
        }
        <b {...titleStyling} >Date of hearing</b>
        {this.state.dateEdit &&
          <DateSelector
            name="hearingDate"
            label={false}
            value={this.state.selectedDate}
            onChange={(option) => option && this.setState({ selectedDate: option })}
            type="date"
          />
        }
        {!this.state.dateEdit &&
          <InlineForm>
            <p {...buttonLinksStyling}>{hearingDateStr}</p>
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
          value={this.state.selectedTime} />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: tasksForAppealAssignedToUserSelector(state, ownProps)[0] ||
    incompleteOrganizationTasksByAssigneeIdSelector(state, { appealId: ownProps.appealId })[0],
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOffices: state.components.regionalOffices
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showErrorMessage,
  resetErrorMessages,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch,
  setTaskAttrs,
  onRegionalOfficeChange
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    AssignHearingModal, { title: 'Schedule Veteran',
      button: 'Schedule' }
  ))
): React.ComponentType<Params>);

