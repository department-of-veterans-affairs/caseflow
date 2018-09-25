import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';
import Modal from '../../components/Modal';

export default function editModalBase(ComponentToWrap, title) {
  class WrappedComponent extends React.Component {
    constructor(props) {
      super(props);

      this.state = { loading: false };
    }

    getWrappedComponentRef = (ref) => this.wrappedComponent = ref;

    closeHandler = () => {
      this.props.history.push(`/queue/appeals/${this.props.appeal.externalId}`);
    }

    submit = () => {
      this.setState({ loading: true });

      this.wrappedComponent.submit().then(() => {
        this.setState({ loading: false });
        this.closeHandler();
      }, () => {
        this.setState({ loading: false });
      });
    }

    render = () => <React.Fragment>
      <Modal
        title={title}
        buttons={[{
          classNames: ['usa-button', 'cf-btn-link'],
          name: 'Cancel',
          onClick: this.closeHandler
        }, {
          classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
          name: 'Submit',
          loading: this.state.loading,
          onClick: this.submit
        }]}
        closeHandler={this.closeHandler}>
        <ComponentToWrap ref={this.getWrappedComponentRef} {...this.props}/>
      </Modal>
    </React.Fragment>;
  }

  return withRouter(WrappedComponent);
}
