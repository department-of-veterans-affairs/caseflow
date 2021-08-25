import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import TextField from '../../components/TextField';
import RadioField from '../../components/RadioField';
import Button from '../../components/Button';

import ApiUtil from 'app/util/ApiUtil';
import {
  TEAM_MANAGEMENT_NAME_COLUMN_HEADING,
  TEAM_MANAGEMENT_URL_COLUMN_HEADING,
  TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING,
  TEAM_MANAGEMENT_UPDATE_ROW_BUTTON
} from 'app/../COPY';

const orgRowStyling = css({
  '&:last_child': { textAlign: 'right' }
});

export class OrgRow extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      accepts_priority_pushed_cases: props.accepts_priority_pushed_cases,
      id: props.id,
      name: props.name,
      url: props.url,
      participant_id: props.participant_id,
      user_admin_path: props.user_admin_path
    };
  }

    changeName = (value) => this.setState({ name: value });
    changeUrl = (value) => this.setState({ url: value });
    changeParticipantId = (value) => this.setState({ participant_id: value });

    changePriorityPush = (judgeTeamId, priorityPush) => {
      const payload = {
        data: {
          organization: {
            accepts_priority_pushed_cases: priorityPush === 'true'
          }
        }
      };

      return ApiUtil.patch(`/team_management/${judgeTeamId}`, payload).
        then((resp) => {
          this.setState({ accepts_priority_pushed_cases: resp.body.org.accepts_priority_pushed_cases });
        });
    };

    // TODO: Add feedback around whether this request was successful or not.
    submitUpdate = () => {
      const options = {
        data: {
          organization: {
            name: this.state.name,
            url: this.state.url,
            participant_id: this.state.participant_id
          }
        }
      };

      return ApiUtil.patch(`/team_management/${this.props.id}`, options).
        then(() => {
          // TODO: Handle the success

          // const response = JSON.parse(resp.text);/

          // this.props.onReceiveAmaTasks(response.tasks.data);
        }).
        catch(() => {
          // TODO: Handle the error.
          // handle the error from the frontend
        });
    }

    // TODO: Indicate that changes have been made to the row by enabling the submit changes button. Default to disabled.
    render = () => {
      const priorityPushRadioOptions = [
        {
          displayText: 'Available',
          value: true,
          disabled: !this.state.accepts_priority_pushed_cases && !this.props.current_user_can_toggle_priority_pushed_cases
        }, {
          displayText: 'Unavailable',
          value: false,
          disabled: this.state.accepts_priority_pushed_cases && !this.props.current_user_can_toggle_priority_pushed_cases
        }
      ];

      return <tr {...orgRowStyling}>
        <td>
          <TextField
            name={`${TEAM_MANAGEMENT_NAME_COLUMN_HEADING}-${this.props.id}`}
            label={false}
            useAriaLabel
            value={this.state.name}
            onChange={this.changeName}
            readOnly={!this.props.isRepresentative}
          />
        </td>
        { this.props.showPriorityPushToggles && <td>
          <RadioField
            id={`priority-push-${this.props.id}`}
            options={priorityPushRadioOptions}
            value={this.state.accepts_priority_pushed_cases}
            onChange={(option) => this.changePriorityPush(this.props.id, option)}
          />
        </td> }
        { this.props.isRepresentative && <td>
          <TextField
            name={`${TEAM_MANAGEMENT_URL_COLUMN_HEADING}-${this.props.id}`}
            label={false}
            useAriaLabel
            value={this.state.url}
            onChange={this.changeUrl}
            readOnly={!this.props.isRepresentative}
          />
        </td> }
        { !this.props.isRepresentative && !this.props.showPriorityPushToggles && <td></td> }
        <td>
          { this.props.isRepresentative &&
            <TextField
              name={`${TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING}-${this.props.id}`}
              label={false}
              useAriaLabel
              value={this.state.participant_id}
              onChange={this.changeParticipantId}
            />
          }
        </td>
        <td>
          { this.props.isRepresentative &&
            <Button
              name={TEAM_MANAGEMENT_UPDATE_ROW_BUTTON}
              id={`${this.props.id}`}
              classNames={['usa-button-secondary']}
              onClick={this.submitUpdate}
            />
          }
        </td>
        <td>
          { this.state.url && this.state.user_admin_path && <Link to={this.state.user_admin_path}>
            <Button
              name="Org Admin Page"
              classNames={['usa-button-secondary']}
            />
          </Link> }
        </td>
      </tr>;
    }
}

OrgRow.defaultProps = {
  isRepresentative: false,
  showPriorityPushToggles: false
};

OrgRow.propTypes = {
  accepts_priority_pushed_cases: PropTypes.bool,
  current_user_can_toggle_priority_pushed_cases: PropTypes.bool,
  id: PropTypes.number,
  name: PropTypes.string,
  participant_id: PropTypes.number,
  isRepresentative: PropTypes.bool,
  showPriorityPushToggles: PropTypes.bool,
  url: PropTypes.string,
  user_admin_path: PropTypes.string
};

