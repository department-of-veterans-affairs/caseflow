import React, { PropTypes } from 'react';
import Button from '../../components/Button';
import ApiUtil from '../../util/ApiUtil';

export default class EstablishClaimToolbar extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      loading: false
    };
  }

  render() {
    let {
      availableTasks,
      buttonText,
      casesAssigned,
      totalCasesCompleted
    } = this.props;

    let NoMoreClaimsButton = () => {
      return <div>
        <span className="cf-button-associated-text-right">
          There are no more claims in your queue
        </span>

        <Button
          name={buttonText}
          classNames={["cf-push-right"]}
          disabled={true}
        />
      </div>;
    };

    let NextClaimButton = () => {
      return <div>
        <span className="cf-button-associated-text-right">
          { casesAssigned } cases assigned, { totalCasesCompleted } completed
        </span>
        <Button
          app="dispatch"
          name={buttonText}
          onClick={this.establishNextClaim}
          classNames={["usa-button-primary", "cf-push-right"]}
          loading={this.state.loading}
        />
      </div>;
    };

    return <div className="cf-app-segment">
      <div className="cf-push-left">
        <a href="/dispatch/establish-claim">View Work History</a>
      </div>

      <div className="cf-push-right">
        { availableTasks && <NextClaimButton /> }
        { !availableTasks && <NoMoreClaimsButton /> }
      </div>
    </div>
  }

  establishNextClaim = () => {
    this.setState({
      loading: true
    });

    ApiUtil.patch(`/dispatch/establish-claim/assign`).
    then((response) => {
      window.location = `/dispatch/establish-claim/${response.body.next_task_id}`;
    }, () => {
      this.props.handleAlert(
        'error',
        'Error',
        'There was an error establishing the next claim. Please try again later'
      );

      this.setState({
        loading: false
      });
    });
  };

}

EstablishClaimToolbar.propTypes = {
  availableTasks: PropTypes.bool,
  buttonText: PropTypes.string,
  casesAssigned: PropTypes.number,
  totalCasesCompleted: PropTypes.number
};