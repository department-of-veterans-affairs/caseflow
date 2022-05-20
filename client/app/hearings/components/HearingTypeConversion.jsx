import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { get } from 'lodash';
import { sprintf } from 'sprintf-js';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import React, { useState, createContext, useEffect } from 'react';

import { VSOHearingTypeConversionForm } from './VSOHearingTypeConversionForm';
import { HearingTypeConversionForm } from './HearingTypeConversionForm';
import { appealWithDetailSelector, taskById } from '../../queue/selectors';
import { deleteAppeal } from '../../queue/QueueActions';
import {
  showErrorMessage,
  showSuccessMessage,
} from '../../queue/uiReducer/uiActions';
import ApiUtil from '../../util/ApiUtil';
import COPY from '../../../COPY';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import { formatChangeRequestType } from '../utils';

export const AppellantTZContext = createContext([{}, () => {}]);
export const AppellantTZErrorContext = createContext([{}, () => {}]);
export const RepresentativeTZContext = createContext([{}, () => {}]);
export const RepresentativeTZErrorContext = createContext([{}, () => {}]);
export const EmptyConfirmContext = createContext([{}, () => {}]);
export const EmptyConfirmMessageContext = createContext([{}, () => {}]);

export const HearingTypeConversion = ({
  appeal,
  history,
  task,
  type,
  userIsVsoEmployee,
  ...props
}) => {
  // Create and manage the loading state
  const [loading, setLoading] = useState(false);

  // Create state for appellant timezone check
  const [isAppellantTZEmpty, setIsAppellantTZEmpty] = useState(true);

  // Create state for appellant timezone error message
  const [appellantTZErrorMessage, setAppellantTZErrorMessage] = useState('');

  // Create state for rep timezone check
  const [isRepTZEmpty, setIsRepTZEmpty] = useState(true);

  // Create state for rep timezone error message
  const [repTZErrorMessage, setRepTZErrorMessage] = useState('');

  // Create state to check if confirm field is empty
  const [confirmIsEmpty, setConfirmIsEmpty] = useState(true);

  // Create state for confirmIsEmpty error message
  const [confirmIsEmptyMessage, setConfirmIsEmptyMessage] = useState('');

  // Function to scroll to top of window
  const scrollUp = () => {
    window.scrollTo({
      top: 0,
      behaviour: 'smooth',
    });
  };

  const getSuccessMsg = () => {
    const title = sprintf(
      COPY.CONVERT_HEARING_TYPE_SUCCESS,
      appeal?.appellantIsNotVeteran ?
        appeal?.appellantFullName :
        appeal?.veteranFullName,
      type
    );
    const detail = sprintf(
      COPY.CONVERT_HEARING_TYPE_SUCCESS_DETAIL,
      appeal?.closestRegionalOfficeLabel ||
        COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT
    );

    return { title, detail };
  };

  // Set Payload based on whether user is VSO or not
  const submit = async () => {
    let data = {};

    if (isAppellantTZEmpty || isRepTZEmpty || confirmIsEmpty) {
      scrollUp();

      if (isAppellantTZEmpty) {
        setAppellantTZErrorMessage('Please enter a timezone');
      }

      if (isRepTZEmpty) {
        setRepTZErrorMessage('Please enter a timezone');
      }

      if (confirmIsEmpty) {
        setConfirmIsEmptyMessage('Please confirm email');
      }

    } else {
      try {
        const changedRequestType = formatChangeRequestType(type);

        if (userIsVsoEmployee) {
          data = {
            task: {
              status: TASK_STATUSES.completed,
              business_payloads: {
                values: {
                  changed_hearing_request_type: changedRequestType,
                  closest_regional_office:
                    appeal?.closestRegionalOffice ||
                    appeal?.regionalOffice?.key,
                  email_recipients: {
                    appellant_tz: appeal?.appellantTz,
                    representative_tz:
                      appeal?.powerOfAttorney?.representative_tz,
                    appellant_email:
                      appeal?.veteranInfo?.veteran?.email_address,
                    representative_email:
                      appeal?.powerOfAttorney?.representative_email_address,
                  },
                },
              },
            },
          };
        } else {
          data = {
            task: {
              status: TASK_STATUSES.completed,
              business_payloads: {
                values: {
                  changed_hearing_request_type: changedRequestType,
                  closest_regional_office:
                    appeal?.closestRegionalOffice ||
                    appeal?.regionalOffice?.key,
                },
              },
            },
          };
        }
        setLoading(true);

        await ApiUtil.patch(`/tasks/${task.taskId}`, { data });

        props.showSuccessMessage(getSuccessMsg());
        props.deleteAppeal(task.externalAppealId);
      } catch (err) {
        const error = get(err, 'response.body.errors[0]', {
          title: COPY.DEFAULT_UPDATE_ERROR_MESSAGE_TITLE,
          detail: COPY.DEFAULT_UPDATE_ERROR_MESSAGE_DETAIL,
        });

        props.showErrorMessage(error);
      } finally {
        setLoading(false);

        history.push(`/queue/appeals/${appeal.externalId}`);
      }
    }
  };

  // Render Convert to Virtual Form Depending on VSO User Status

  return (
    <EmptyConfirmMessageContext.Provider value={[confirmIsEmptyMessage, setConfirmIsEmptyMessage]}>
      <EmptyConfirmContext.Provider value={[confirmIsEmpty, setConfirmIsEmpty]}>
        <RepresentativeTZErrorContext.Provider value={[repTZErrorMessage, setRepTZErrorMessage]}>
          <RepresentativeTZContext.Provider value={[isRepTZEmpty, setIsRepTZEmpty]}>
            <AppellantTZErrorContext.Provider value={[appellantTZErrorMessage, setAppellantTZErrorMessage]}>
              <AppellantTZContext.Provider
                value={[isAppellantTZEmpty, setIsAppellantTZEmpty]}
              >
                {userIsVsoEmployee ? (
                  <VSOHearingTypeConversionForm
                    appeal={appeal}
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
                )}
              </AppellantTZContext.Provider>
            </AppellantTZErrorContext.Provider>
          </RepresentativeTZContext.Provider>
        </RepresentativeTZErrorContext.Provider>
      </EmptyConfirmContext.Provider>
    </EmptyConfirmMessageContext.Provider>
  );
};

HearingTypeConversion.propTypes = {
  appeal: PropTypes.object,
  appealId: PropTypes.string,
  deleteAppeal: PropTypes.func,
  showErrorMessage: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  task: PropTypes.object,
  taskId: PropTypes.string,
  type: PropTypes.oneOf(['Virtual']),
  // Router inherited props
  history: PropTypes.object,
  userIsVsoEmployee: PropTypes.bool,
};

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId }),
  userIsVsoEmployee: state.ui.userIsVsoEmployee,
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      deleteAppeal,
      showErrorMessage,
      showSuccessMessage,
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(HearingTypeConversion)
);
