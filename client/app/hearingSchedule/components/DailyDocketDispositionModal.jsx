import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Modal from '../../components/Modal';
import Button from '../../components/Button';

const COPY = {
  CASEFLOW: {
    body: <span>
      <p>You are changing the hearing disposition for this case.
        Changing the disposition will change where the case is sent next</p>
      <p>The Daily Docket will be locekd the day after the hearing date and will
        require administrative access to change after that time.</p>
    </span>,
    title: 'Change hearing disposition'
  },
  VACOLS: {
    body: <span>
      <p>You are changing the disposition of a VACOLS hearing.
      Use VACOLS to track this hearing and move the case location in VACOLS if necessary.</p>
    </span>,
    title: 'VACOLS hearing disposition'
  }
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
      new Date(hearing.scheduledFor) < new Date(4, 1, 2019) ? 'VACOLS' : 'CASEFLOW';

    return (
      <AppSegment filledBackground>
        <div className="cf-modal-scroll">
          <Modal
            closeHandler={onCancel}
            confirmButton={this.confirmButton()}
            cancelButton={this.cancelButton()}
            title={COPY[hearingType].title}>
            <div>
              <p>Previous Disposition: {hearing.disposition}</p>
              <p>New Disposition: {disposition}</p>
            </div>
            {COPY[hearingType].body}
          </Modal>
        </div>
      </AppSegment>
    );
  }
}
