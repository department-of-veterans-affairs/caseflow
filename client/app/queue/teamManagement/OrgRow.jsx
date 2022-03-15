import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import TextField from 'app/components/TextField';
import Button from 'app/components/Button';
import SearchableDropdown from 'app/components/SearchableDropdown';

import {
  TEAM_MANAGEMENT_NAME_COLUMN_HEADING,
  TEAM_MANAGEMENT_URL_COLUMN_HEADING,
  TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING,
  TEAM_MANAGEMENT_UPDATE_ROW_BUTTON,
} from 'app/../COPY';

const orgRowStyling = css({
  '&:last_child': { textAlign: 'right' },
});

const dropdownStyling = css({
  width: '300px'
});

const statusIndicator = css({
  '&': { width: '11.5ch' },
  '& span': {
    display: 'inline-block',
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    width: '8ch'
  },
  '& span.success': { color: '#2E8540' }
});

export const priorityPushOpts = [
  { label: 'All cases', value: 'all' },
  { label: 'AMA cases only', value: 'amaOnly' },
  { label: 'Unavailable', value: 'unavailable' },
];

export const requestCasesOpts = [
  { label: 'All cases', value: 'all' },
  { label: 'AMA cases only', value: 'amaOnly' },
];

const initialPriorityPushVal = (props) => {
  if (!props.accepts_priority_pushed_cases) {
    return 'unavailable';
  }

  return props.ama_only_push ? 'amaOnly' : 'all';
};

export const OrgRow = React.memo((props) => {
  const [name, setName] = useState(props.name);
  const [url, setUrl] = useState(props.url);
  const [participantId, setParticipantId] = useState(props.participant_id);
  const [priorityCaseDistribution, setPriorityCaseDistribution] = useState(initialPriorityPushVal(props));
  const [requestedCaseDistribution, setRequestedCaseDistribution] = useState(
    props.ama_only_request ? 'amaOnly' : 'all'
  );

  const handleUpdate = () => {
    const payload = {
      name,
      url,
      participant_id: participantId,
    };

    props.onUpdate?.(props.id, payload);
  };
  const handlePriorityCaseDistribution = ({ value }) => {
    setPriorityCaseDistribution(value);
    const payload = {
      accepts_priority_pushed_cases: ['all', 'amaOnly'].includes(value),
      ama_only_push: ['amaOnly'].includes(value),
    };

    props.onUpdate?.(props.id, payload);
  };
  const handleRequestedCaseDistribution = ({ value }) => {
    setRequestedCaseDistribution(value);
    const payload = {
      ama_only_request: ['amaOnly'].includes(value),
    };

    props.onUpdate?.(props.id, payload);
  };

  return (
    <tr {...orgRowStyling}>
      <td>
        {!props.isRepresentative && (
          <span>{name || <em>Name not set</em>}</span>
        )}

        {props.isRepresentative && (
          <TextField
            name={`${TEAM_MANAGEMENT_NAME_COLUMN_HEADING}-${props.id}`}
            label={false}
            useAriaLabel
            value={name}
            onChange={setName}
          />
        )}
      </td>
      {props.showDistributionToggles && (
        <>
          <td className={dropdownStyling}>
            <SearchableDropdown
              name={`priorityCaseDistribution-${props.id}`}
              hideLabel
              options={priorityPushOpts}
              readOnly={!props.current_user_can_toggle_priority_pushed_cases}
              value={priorityCaseDistribution}
              onChange={handlePriorityCaseDistribution}
            />
          </td>
          <td className={dropdownStyling}>
            <SearchableDropdown
              name={`requestedDistribution-${props.id}`}
              hideLabel
              options={requestCasesOpts}
              readOnly={!props.current_user_can_toggle_priority_pushed_cases}
              value={requestedCaseDistribution}
              onChange={handleRequestedCaseDistribution}
            />
          </td>
        </>
      )}
      {props.isRepresentative && (
        <td>
          <TextField
            name={`${TEAM_MANAGEMENT_URL_COLUMN_HEADING}-${props.id}`}
            label={false}
            useAriaLabel
            value={url}
            onChange={setUrl}
            readOnly={!props.isRepresentative}
          />
        </td>
      )}

      {props.isRepresentative && (
        <td>
          <TextField
            name={`${TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING}-${
              props.id
            }`}
            label={false}
            useAriaLabel
            value={participantId}
            onChange={setParticipantId}
          />
        </td>
      )}

      {props.isRepresentative && (
        <td>
          <Button
            name={TEAM_MANAGEMENT_UPDATE_ROW_BUTTON}
            id={`${props.id}`}
            classNames={['usa-button-secondary']}
            onClick={handleUpdate}
          />
        </td>
      )}

      <td className={statusIndicator}>
        {props.status?.saved && (
          <span className="success" role="status"><i className="fa fa-check-circle"></i> Saved</span>
        )}
        {props.status?.loading && (
          <span className="loading" role="status"><i className="fa fa-spinner fa-spin"></i> Saving</span>
        )}
        {props.status?.error && (
          <span className="error" role="status"><i className="fa fa-times"></i> Error</span>
        )}
      </td>
      <td>
        {url && props.user_admin_path && (
          <Link to={props.user_admin_path}>
            <Button
              name="Org Admin Page"
              classNames={['usa-button-secondary']}
            />
          </Link>
        )}
      </td>
    </tr>
  );
});

OrgRow.defaultProps = {
  isRepresentative: false,
  showDistributionToggles: false,
};

OrgRow.propTypes = {
  accepts_priority_pushed_cases: PropTypes.bool,
  ama_only_push: PropTypes.bool,
  ama_only_request: PropTypes.bool,
  current_user_can_toggle_priority_pushed_cases: PropTypes.bool,
  id: PropTypes.number,
  name: PropTypes.string,
  participant_id: PropTypes.string,
  isRepresentative: PropTypes.bool,
  showDistributionToggles: PropTypes.bool,
  url: PropTypes.string,
  user_admin_path: PropTypes.string,
  editableName: PropTypes.bool,
  onUpdate: PropTypes.func,
  status: PropTypes.shape({
    loading: PropTypes.bool,
    saved: PropTypes.bool,
    error: PropTypes.bool,
  })
};
