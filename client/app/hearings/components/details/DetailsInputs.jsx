import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import { rowThirds } from './style';
import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from '../../../components/DataDropdowns/index';
import TextareaField from '../../../components/TextareaField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import Checkbox from '../../../components/Checkbox';

const DetailsInputs = ({
  hearing, update, readOnly, isLegacy, openModal, updateVirtualHearing, virtualHearing,
  enableVirtualHearings
}) => (
  <React.Fragment>
    <div {...rowThirds}>
      {enableVirtualHearings && <SearchableDropdown
        label="Hearing Type"
        name="hearingType"
        strongLabel
        options={[
          {
            value: false,
            label: 'Video'
          },
          {
            value: true,
            label: 'Virtual'
          }
        ]}
        value={(virtualHearing && virtualHearing.active) || false}
        onChange={(option) => {
          if ((virtualHearing && virtualHearing.active) || option.value) {
            openModal();
          }
          updateVirtualHearing({ active: option.value });
        }}
      />}
    </div>
    <div {...rowThirds}>
      <JudgeDropdown
        name="judgeDropdown"
        value={hearing.judgeId}
        readOnly={readOnly}
        onChange={(judgeId) => update({ judgeId })}
      />
    </div>
    <div {...rowThirds}>
      <HearingRoomDropdown
        name="hearingRoomDropdown"
        value={hearing.room}
        readOnly={readOnly}
        onChange={(room) => update({ room })}
      />
      <HearingCoordinatorDropdown
        name="hearingCoordinatorDropdown"
        value={hearing.bvaPoc}
        readOnly={readOnly}
        onChange={(bvaPoc) => update({ bvaPoc })}
      />
      {!isLegacy &&
        <div>
          <strong>Waive 90 Day Evidence Hold</strong>
          <Checkbox
            label="Yes, Waive 90 Day Evidence Hold"
            name="evidenceWindowWaived"
            disabled={readOnly}
            value={hearing.evidenceWindowWaived || false}
            onChange={(evidenceWindowWaived) => update({ evidenceWindowWaived })}
          />
        </div>
      }
    </div>
    <TextareaField
      name="Notes"
      strongLabel
      styling={css({
        display: 'block',
        maxWidth: '100%'
      })}
      disabled={readOnly}
      value={hearing.notes || ''}
      onChange={(notes) => update({ notes })}
    />
  </React.Fragment>
);

DetailsInputs.propTypes = {
  hearing: PropTypes.shape({
    judgeId: PropTypes.string,
    room: PropTypes.string,
    evidenceWindowWaived: PropTypes.bool,
    notes: PropTypes.string,
    bvaPoc: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  isLegacy: PropTypes.bool,
  openModal: PropTypes.func,
  updateVirtualHearing: PropTypes.func,
  virtualHearing: PropTypes.shape({
    active: PropTypes.bool
  }),
  enableVirtualHearings: PropTypes.bool
};

export default DetailsInputs;
