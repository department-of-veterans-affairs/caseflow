import _ from 'lodash';
import { connect } from 'react-redux';
import React from 'react';

import Modal from '../../components/Modal';
import { formatDateStr } from '../../util/DateUtil';
import RadioField from '../../components/RadioField';

class AddIssuesModal extends React.Component {
  render() {
    let {
      ratings,
      closeHandler
    } = this.props;

    const ratedIssuesSections = _.map(ratings, (rating) => {
      const radioOptions = _.map(rating.issues, (issue) => {
        return {
          displayText: issue.decision_text,
          value: issue.reference_id
        }
      });

      return <RadioField
        vertical
        label={<h3>Past decisions from { formatDateStr(rating.profile_date) }</h3>}
        name={ 'rating-radio-' + rating.profile_date }
        options={ radioOptions }
        key={ rating.profile_date }
        // todo, implement onChange
      />
    });

    return <div>
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Close',
            onClick: closeHandler
          },
          { classNames: ['usa-button', 'usa-button-secondary', 'add-issue'],
            name: 'Add Issue',
            onClick: () => {}
          }
        ]}

        visible
        closeHandler={ closeHandler }
        title='Add Issue'
        >
        <div>
          <h2>
            Does this issue match any of these issues from past descriptions?
          </h2>
          <p>
            Tip: sometimes applicants list desired outcome, not what the past decision was -- so select the best matching decision.
          </p>
          <br/>
          { ratedIssuesSections }
        </div>
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  null
)(AddIssuesModal);
