import React, { PropTypes } from 'react';

import Table from '../../components/Table';
import Button from '../../components/Button';
import { formatDate } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';

const TABLE_HEADERS = ['Decision Date', 'EP Code', 'Status', 'Select this EP'];

export default class AssociatePage extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      loading: null,
      sortedEndProducts: this.props.endProducts.sort(this.sortEndProduct)
    };
  }

  componentWillMount() {
    if (!this.props.endProducts.length) {
      this.props.history.goBack();
    }
  }

  buildEndProductRow = (endProduct) => [
    formatDate(endProduct.claim_receive_date),
    endProduct.claim_type_code,
    endProduct.status_type_code,
    <Button
      id={`button-Assign-to-Claim${endProduct.benefit_claim_id}`}
      name="Assign to Claim"
      classNames={["usa-button-outline"]}
      onClick={this.handleAssignEndProduct(endProduct)}
      loading={this.state.loading === endProduct.benefit_claim_id}
    />
  ];

  handleAssignEndProduct = (endProduct) => (event) => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    event.preventDefault();
    handleAlertClear();

    this.setState({
      loading: endProduct.benefit_claim_id
    });

    let data = ApiUtil.convertToSnakeCase({
      endProductId: endProduct.benefit_claim_id,
      specialIssues: this.props.specialIssues
    });

    return ApiUtil.post(
      `/dispatch/establish-claim/${id}/assign-existing-end-product`,
      { data }).then(() => {
        window.location.reload();
      }, () => {
        this.setState({
          loading: null
        });
        handleAlert(
          'error',
          'Error',
          'There was an error while assigning the EP. Please try again later'
        );
      });
  }

  sortEndProduct = (date1, date2) => {
    let time1 = new Date(date1.claim_receive_date).getTime();
    let time2 = new Date(date2.claim_receive_date).getTime();

    return time2 - time1;
  }

  render() {
    let {
      handleCancelTask,
      handleBackToDecisionReview,
      handleSubmit,
      hasAvailableModifers
    } = this.props;

    let alert, title;

    if (this.props.hasAvailableModifers) {
      title = <h1>Route Claim: Existing End Product(s)</h1>;
      alert = <div><h3 className="usa-alert-heading">Existing EP</h3>
        <p className="usa-alert-text">We found one or more existing EP(s)
          created within 30 days of this decision date.
          Please review the existing EP(s) in the table below.
          Select one to assign to this claim or create a new EP.
        </p>
      </div>;
    } else {
      title = <h1>Route Claim: Create End Product</h1>;
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
        <div className="usa-alert usa-alert-warning">
          <div className="usa-alert-body">
            {alert}
          </div>
        </div>
        <div className="usa-grid-full">
          <Table
            headers={TABLE_HEADERS}
            buildRowValues={this.buildEndProductRow}
            values={this.state.sortedEndProducts}
          />
        </div>
      </div>
      <div className="cf-app-segment" id="establish-claim-buttons">
        <div className="cf-push-left">
          <Button
            name="< Back to Decision Review"
            onClick={handleBackToDecisionReview}
            classNames={["cf-btn-link"]}
          />
        </div>
        <div className="cf-push-right">
          <Button
            name="Cancel"
            onClick={handleCancelTask}
            classNames={["cf-btn-link", "cf-adjacent-buttons"]}
          />
          <Button
            name="Create New EP"
            onClick={handleSubmit}
            disabled={!hasAvailableModifers}
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
  handleSubmit: PropTypes.func.isRequired,
  hasAvailableModifers: PropTypes.bool.isRequired,
  specialIssues: PropTypes.object.isRequired,
  task: PropTypes.object.isRequired
};
