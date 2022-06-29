import { get } from 'lodash';
import { sprintf } from 'sprintf-js';
import PropTypes from 'prop-types';
import React, { useState, useContext } from 'react';

import HearingTypeConversionContext from '../contexts/HearingTypeConversionContext';
import { VSOHearingTypeConversionForm } from './VSOHearingTypeConversionForm';
import { HearingTypeConversionForm } from './HearingTypeConversionForm';
import ApiUtil from '../../util/ApiUtil';
import COPY from '../../../COPY';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import { formatChangeRequestType } from '../utils';

export const HearingTypeConversion = ({
  appeal,
  history,
  task,
  type,
  userIsVsoEmployee,
  ...props
}) => {
  const [loading, setLoading] = useState(false);

  const { updatedAppeal } = useContext(HearingTypeConversionContext);

  const getSuccessMsg = () => {
    const title = sprintf(
      COPY.CONVERT_HEARING_TYPE_SUCCESS,
      appeal?.appellantIsNotVeteran ?
        appeal?.appellantFullName :
        appeal?.veteranFullName,
      type.toLowerCase()
    );
    const detail = userIsVsoEmployee ?
      COPY.VSO_CONVERT_HEARING_TYPE_SUCCESS_DETAIL :
      sprintf(
        COPY.CONVERT_HEARING_TYPE_SUCCESS_DETAIL,
          appeal?.closestRegionalOfficeLabel ||
            COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT
      );

    return { title, detail };
  };

  // Set Payload based on whether user is VSO or not
  const submit = async () => {
    try {
      const changedRequestType = formatChangeRequestType(type);

      const data = {
        task: {
          status: TASK_STATUSES.completed,
          business_payloads: {
            values: {
              changed_hearing_request_type: changedRequestType,
              closest_regional_office: appeal?.closestRegionalOffice || appeal?.regionalOffice?.key,
              ...(userIsVsoEmployee && {
                email_recipients: {
                  appellant_tz: updatedAppeal?.appellantTz,
                  representative_tz: updatedAppeal?.representativeTz,
                  appellant_email: updatedAppeal?.appellantEmailAddress,
                  representative_email: updatedAppeal?.currentUserEmail
                }
              })
            }
          }
        }
      };

      setLoading(true);

      await ApiUtil.patch(`/tasks/${task.taskId}`, { data });

      props.showSuccessMessage(getSuccessMsg());
      props.deleteAppeal(task.externalAppealId);
    } catch (err) {
      const error = get(err, 'response.body.errors[0]', {
        title: COPY.DEFAULT_UPDATE_ERROR_MESSAGE_TITLE,
        detail: COPY.DEFAULT_UPDATE_ERROR_MESSAGE_DETAIL
      });

      props.showErrorMessage(error);
    } finally {
      setLoading(false);

      history.push(`/queue/appeals/${appeal.externalId}`);
    }
  };

  return userIsVsoEmployee ? (
    <VSOHearingTypeConversionForm
      history={history}
      isLoading={loading}
      onCancel={() => history.goBack()}
      onSubmit={submit}
      task={task}
      type={type}
    />
  ) : (
    <HearingTypeConversionForm
      appeal={appeal}
      history={history}
      isLoading={loading}
      onCancel={() => history.goBack()}
      onSubmit={submit}
      task={task}
      type={type}
    />
  );
};

HearingTypeConversion.propTypes = {
  appeal: PropTypes.object,
  deleteAppeal: PropTypes.func,
  showErrorMessage: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  task: PropTypes.object,
  type: PropTypes.oneOf(['Virtual']),
  history: PropTypes.object,
  userIsVsoEmployee: PropTypes.bool,
};
