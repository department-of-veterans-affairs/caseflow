import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import classnames from 'classnames';
import { rowThirds } from './style';
import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from '../../../components/DataDropdowns/index';
import TextareaField from '../../../components/TextareaField';
import Checkbox from '../../../components/Checkbox';
import VirtualHearingLink from '../VirtualHearingLink';
import HearingTypeDropdown from './HearingTypeDropdown';
import TextField from '../../../components/TextField';
import { COLORS } from '../../../constants/AppConstants';
import COPY from '../../../../COPY.json';

class DetailsInputs extends React.Component {

  renderVirtualHearingLinkSection() {
    const { isVirtual, hearing, virtualHearing, user } = this.props;

    if (isVirtual && virtualHearing) {
      return (
        <div>
          <strong>Virtual Hearing Link</strong>
          <div {...css({ marginTop: '1.5rem' })}>
            {virtualHearing.jobCompleted &&
              <VirtualHearingLink
                role={user.userId.toString() === hearing.judgeId ? 'host' : 'guest'}
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
              readOnly={isVirtual && virtualHearing && !virtualHearing.jobCompleted}
            />
            {this.renderVirtualHearingLinkSection()}
          </div>
        }
        {isVirtual && virtualHearing &&
          <div {...rowThirds}>
            <TextField
              name="Veteran Email"
              value={virtualHearing.veteranEmail}
              strongLabel
              required
              className={[classnames('cf-form-textinput', 'cf-inline-field')]}
              readOnly={!virtualHearing.jobCompleted}
              onChange={(veteranEmail) => updateVirtualHearing({ veteranEmail })}
            />
            <TextField
              name="POA/Representive Email"
              value={virtualHearing.representativeEmail}
              strongLabel
              className={[classnames('cf-form-textinput', 'cf-inline-field')]}
              readOnly={!virtualHearing.jobCompleted}
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
    bvaPoc: PropTypes.string
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
  isVirtual: PropTypes.bool
};

export default DetailsInputs;
