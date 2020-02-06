import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import Table from '../../components/Table';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import { formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import * as Constants from '../../establishClaim/constants';
import WindowUtil from '../../util/WindowUtil';

export class AssociatePage extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      epLoading: null,
      sortedEndProducts: this.props.endProducts.sort(this.sortEndProduct)
    };
  }

  // eslint-disable-next-line camelcase
  UNSAFE_componentWillMount() {
    if (!this.props.endProducts.length) {
      this.props.history.goBack();
    }
  }

  getEndProductColumns = () => [
    {
      header: 'Decision Date',
      valueFunction: (endProduct) =>
        formatDateStr(endProduct.claim_receive_date)
    },
    {
      header: 'EP Code',
      valueName: 'claim_type_code'
    },
    {
      header: 'Status',
      valueName: 'status_type_code'
    },
    {
      header: 'Select this EP',
      valueFunction: (endProduct) =>
        <Button
          app="dispatch"
          id={`button-Assign-to-Claim${endProduct.benefit_claim_id}`}
          name="Assign to Claim"
          classNames={
            this.getClassAssignButtonClasses(
              this.state.epLoading,
              endProduct.benefit_claim_id
            )
          }
          onClick={this.handleAssignEndProduct(endProduct)}
          loading={this.state.epLoading === endProduct.benefit_claim_id}
        />
    }
  ];

  getClassAssignButtonClasses = (loadingFlag, claimId) => {
    let classes = ['usa-button-secondary'];

    if (loadingFlag) {
      classes.push('usa-button-disabled');
      if (loadingFlag !== claimId) {
        classes.push('cf-secondary-disabled');
      }
    }

    return classes;
  }

  handleAssignEndProduct = (endProduct) => (event) => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    event.preventDefault();
    handleAlertClear();

    this.setState({
      epLoading: endProduct.benefit_claim_id
    });

    let data = ApiUtil.convertToSnakeCase({
      endProductId: endProduct.benefit_claim_id
    });

    return ApiUtil.post(
      `/dispatch/establish-claim/${id}/assign-existing-end-product`,
      { data }).then(() => {
      WindowUtil.reloadWithPOST();
      this.setState({
        epLoading: null
      });
    }, () => {
      handleAlert(
        'error',
        'Error',
        'There was an error while assigning the EP. Please try again later'
      );
      this.setState({
        epLoading: null
      });
    });
  }

  sortEndProduct = (date1, date2) => {
    let time1 = new Date(date1.claim_receive_date).getTime();
    let time2 = new Date(date2.claim_receive_date).getTime();

    return time2 - time1;
  }

  render() {
    let {
      handleSubmit,
      handleToggleCancelTaskModal,
      handleBackToDecisionReview,
      backToDecisionReviewText,
      hasAvailableModifers,
      loading
    } = this.props;

    let alert, title;

    if (this.props.hasAvailableModifers) {
      title = <span> <h1>Route Claim</h1>
        <h2> Existing End Product(s)</h2></span>;
      alert = <div><h3 className="usa-alert-heading">Existing EP</h3>
        <p className="usa-alert-text">We found one or more existing EP(s)
          created within 30 days of this decision date.
          Please review the existing EP(s) in the table below.
          Select one to assign to this claim or create a new EP.
        </p>
      </div>;
    } else {
      title = <span><h1>Route Claim</h1>
        <h2>Create End Product</h2></span>;
      alert = <div><h3 className="usa-alert-heading">
          Existing EP, all EP & Claim Label Modifiers in use
      </h3>
      <p className="usa-alert-text">We found one or more existing EP(s)
          created within 30 days of this decision date. You may assign a
          existing EP from the table below to this claim.
      </p>
      <p className="usa-alert-text">
          A new {this.props.decisionType} EP cannot be created for this Veteran
          ID as all EP modifiers are currently in use.
      </p>
      </div>;
    }

    return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        {title}
        <Alert
          type="warning">
          {alert}
        </Alert>
        <div className="usa-width-one-whole">
          <Table
            columns={this.getEndProductColumns()}
            rowObjects={this.state.sortedEndProducts}
            summary="Existing end products for this veteran"
          />
        </div>
      </div>
      <div className="cf-app-segment" id="establish-claim-buttons">
        <div className="cf-push-left">
          <Button
            name={backToDecisionReviewText}
            onClick={handleBackToDecisionReview}
            classNames={['cf-btn-link']}
          />
        </div>
        <div className="cf-push-right">
          <Button
            name="Cancel"
            onClick={handleToggleCancelTaskModal}
            classNames={['cf-btn-link']}
          />
          <Button
            app="dispatch"
            name="Create new EP"
            onClick={handleSubmit}
            disabled={!hasAvailableModifers || (this.state.epLoading !== null)}
            loading={loading}
          />
        </div>
      </div>
    </div>;
  }
}

AssociatePage.propTypes = {
  decisionType: PropTypes.string.isRequired,
  endProducts: PropTypes.arrayOf(PropTypes.object).isRequired,
  handleAlert: PropTypes.func.isRequired,
  handleAlertClear: PropTypes.func.isRequired,
  handleBackToDecisionReview: PropTypes.func.isRequired,
  handleToggleCancelTaskModal: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  backToDecisionReviewText: PropTypes.string.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  hasAvailableModifers: PropTypes.bool.isRequired,
  task: PropTypes.object.isRequired,
  loading: PropTypes.bool
};

const mapStateToProps = (state) => ({
  specialIssues: state.specialIssues
});

const mapDispatchToProps = (dispatch) => ({
  handleToggleCancelTaskModal: () => {
    dispatch({ type: Constants.TOGGLE_CANCEL_TASK_MODAL });
  }
});

const ConnectedEstablishClaimAssociateEP = connect(
  mapStateToProps,
  mapDispatchToProps
)(AssociatePage);

export default ConnectedEstablishClaimAssociateEP;
