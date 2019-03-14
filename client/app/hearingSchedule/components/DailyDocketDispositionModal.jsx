import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Modal from '../../components/Modal';
import Button from '../../components/Button';

const COPY = {
  CASEFLOW: {
    body: <span>
      <p>You are changing the hearing disposition for this case.
        Changing the disposition will change where the case is sent next</p>
      <p>The Daily Docket will be locked the day after the hearing date and will
        require administrative access to change after that time.</p>
    </span>,
    title: 'Change hearing disposition'
  },
  VACOLS: {
    body: <span>
      <p>You are changing the disposition of a hearing being tracked in VACOLS.
        Please move the location in VACOLS if necessary.</p>
    </span>,
    title: 'VACOLS hearing disposition'
  }
};

const dispositionMap = {
  postponed: 'Postponed',
  no_show: 'No show',
  held: 'Held',
  cancelled: 'Canceled'
};

export default class DispositionModal extends React.Component {
  cancelButton = () => {
    return <Button linkStyling onClick={this.props.onCancel}>Go back</Button>;
  };

  confirmButton = () => {
    return <Button
      classNames={['usa-button-secondary']}
      onClick={this.props.onConfirm}
    >Confirm
    </Button>;
  };

  submit = () => {
    this.props.onConfirm();
  }

  render () {
    const { hearing, disposition, onCancel } = this.props;
    const hearingType = hearing.docketName === 'Legacy' &&
      !hearing.dispositionEditable ? 'VACOLS' : 'CASEFLOW';

    return (
      <AppSegment filledBackground>
        <div className="cf-modal-scroll">
          <Modal
            closeHandler={onCancel}
            confirmButton={this.confirmButton()}
            cancelButton={this.cancelButton()}
            title={COPY[hearingType].title}>
            <div>
              <p>
                Previous Disposition: <strong>
                  {hearing.disposition ? dispositionMap[hearing.disposition] : 'None'}
                </strong>
              </p>
              <p>New Disposition: <strong>{dispositionMap[disposition]}</strong></p>
            </div>
            {COPY[hearingType].body}
          </Modal>
        </div>
      </AppSegment>
    );
  }
}
