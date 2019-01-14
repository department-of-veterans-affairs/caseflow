import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import ApiUtil from '../../util/ApiUtil';


class HearingDetailsContainer extends React.Component {


  render() {
    return null;
  }
}


const mapStateToProps = (state) => ({

});

const mapDispatchToProps = (dispatch) => bindActionCreators({

}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingDetailsContainer);
