import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import classnames from 'classnames';

import { COLORS } from '../../../constants/AppConstants';
import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from '../../../components/DataDropdowns/index';
import { VIRTUAL_HEARING_HOST, virtualHearingRoleForUser } from '../../utils';
import { rowThirds } from './style';
import COPY from '../../../../COPY';
import Checkbox from '../../../components/Checkbox';
import HearingTypeDropdown from './HearingTypeDropdown';
import TextField from '../../../components/TextField';
import TextareaField from '../../../components/TextareaField';
import VirtualHearingLink from '../VirtualHearingLink';

class DetailsInputs extends React.Component {
  renderVirtualHearingLinkSection() {
    const { isVirtual, virtualHearing, user, hearing } = this.props;
    const virtualHearingLabel = virtualHearingRoleForUser(user, hearing) === VIRTUAL_HEARING_HOST ?
      COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL :
      COPY.REPRESENTATIVE_VIRTUAL_HEARING_LINK_LABEL;

    if (isVirtual && virtualHearing) {
      return (
        <div>
          <strong>{virtualHearingLabel}</strong>
          <div {...css({ marginTop: '1.5rem' })}>
            {virtualHearing.jobCompleted &&
              <VirtualHearingLink
                user={user}
                hearing={hearing}
                showFullLink
                isVirtual={isVirtual}
                virtualHearing={virtualHearing}
              />
            }
            {!virtualHearing.jobCompleted &&
              <span {...css({ color: COLORS.GREY_MEDIUM })}>
                {COPY.VIRTUAL_HEARING_SCHEDULING_IN_PROGRESS}
              </span>
            }
          </div>
        </div>
      );
    }

    return null;
  }

  showEmailFields = () => {
    const { isVirtual, wasVirtual, virtualHearing } = this.props;

    return (isVirtual || wasVirtual) && virtualHearing;
  }

  readOnlyEmails = () => {
    const { readOnly, wasVirtual, virtualHearing, hearing } = this.props;

    return readOnly || !virtualHearing.jobCompleted || wasVirtual || hearing.scheduledForIsPast;
  }

  render() {
    const {
      hearing, update, readOnly, isLegacy, openVirtualHearingModal, updateVirtualHearing,
      virtualHearing, enableVirtualHearings, requestType, isVirtual
    } = this.props;

    return (
      <React.Fragment>
        {enableVirtualHearings &&
          <div {...rowThirds}>
            <HearingTypeDropdown
              virtualHearing={virtualHearing}
              requestType={requestType}
              updateVirtualHearing={updateVirtualHearing}
              openModal={openVirtualHearingModal}
              readOnly={hearing.scheduledForIsPast || (isVirtual && virtualHearing && !virtualHearing.jobCompleted)}
            />
            {this.renderVirtualHearingLinkSection()}
          </div>
        }
        {this.showEmailFields() &&
          <div {...rowThirds}>
            <TextField
              name="Veteran Email"
              value={virtualHearing.veteranEmail}
              strongLabel
              required
              className={[classnames('cf-form-textinput', 'cf-inline-field')]}
              readOnly={this.readOnlyEmails()}
              onChange={(veteranEmail) => updateVirtualHearing({ veteranEmail })}
            />
            <TextField
              name="POA/Representative Email"
              value={virtualHearing.representativeEmail}
              strongLabel
              className={[classnames('cf-form-textinput', 'cf-inline-field')]}
              readOnly={this.readOnlyEmails()}
              onChange={(representativeEmail) => updateVirtualHearing({ representativeEmail })}
            />
          </div>
        }
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
  }
}

DetailsInputs.propTypes = {
  user: PropTypes.shape({
    userId: PropTypes.number
  }),
  hearing: PropTypes.shape({
    judgeId: PropTypes.string,
    room: PropTypes.string,
    evidenceWindowWaived: PropTypes.bool,
    notes: PropTypes.string,
    bvaPoc: PropTypes.string,
    scheduledForIsPast: PropTypes.bool
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  requestType: PropTypes.string,
  isLegacy: PropTypes.bool,
  openVirtualHearingModal: PropTypes.func,
  updateVirtualHearing: PropTypes.func,
  virtualHearing: PropTypes.shape({
    veteranEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    status: PropTypes.string,
    jobCompleted: PropTypes.bool
  }),
  enableVirtualHearings: PropTypes.bool,
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool
};

export default DetailsInputs;
