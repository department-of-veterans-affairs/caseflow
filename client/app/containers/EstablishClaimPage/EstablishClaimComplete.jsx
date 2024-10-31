import React from 'react';
import PropTypes from 'prop-types';

import EstablishClaimProgressBar from './EstablishClaimProgressBar';
import EstablishClaimToolbar from './EstablishClaimToolbar';
import StatusMessage from '../../components/StatusMessage';

export default class EstablishClaimComplete extends React.Component {

  render() {

    let {
      availableTasks,
      buttonText,
      checklist,
      firstHeader,
      handleAlert,
      handleAlertClear,
      totalCasesCompleted,
      userQuotas,
      userId,
      veteranName
    } = this.props;

    let availableTasksMessage, casesAssigned,hasQuotaReached, quotaReachedMessage, secondHeader;

    availableTasksMessage = availableTasks ? 'You can now establish the next claim or return to your Work History.' :
      'You can now close Caseflow or return to your Work History.';

    secondHeader = <span>{veteranName}'s claim has been processed. <br />
      {availableTasksMessage}
    </span>;

    let userQuota = userQuotas.find(userQuota => userQuota.user_id === userId)
    console.log(userQuotas)
    quotaReachedMessage = () => {
      if (hasQuotaReached) {
        return <span>
          <h2>Way to go!</h2> 💪💻🇺🇸<br />
          <h2 className ="cf-msg-screen-deck cf-success-emoji-text">
             You have completed all of the total cases assigned to you today.
          </h2>
        </span>;
      }
    };

    casesAssigned = userQuota.task_count

    hasQuotaReached = (totalCasesCompleted >= casesAssigned) && (casesAssigned > 0);

    return <div>
      <EstablishClaimProgressBar
        isConfirmation
      />

      <StatusMessage
        title={firstHeader}
        leadMessageList={[secondHeader]}
        checklist={checklist}
        messageText={hasQuotaReached && quotaReachedMessage()}
        type="success"
      />

      <EstablishClaimToolbar
        availableTasks={availableTasks}
        buttonText={buttonText}
        casesAssigned={casesAssigned}
        totalCasesCompleted={totalCasesCompleted}
        handleAlert={handleAlert}
        handleAlertClear={handleAlertClear}
      />
    </div>;
  }

}

EstablishClaimComplete.propTypes = {
  availableTasks: PropTypes.bool,
  buttonText: PropTypes.string,
  checklist: PropTypes.array,
  employeeCount: PropTypes.number,
  firstHeader: PropTypes.string,
  totalCasesAssigned: PropTypes.number,
  totalCasesCompleted: PropTypes.number,
  userId: PropTypes.number,
  userQuotas: PropTypes.arrayOf(PropTypes.object).isRequired,
  veteranName: PropTypes.string
};
