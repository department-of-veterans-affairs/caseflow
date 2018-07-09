import React from 'react';
import { connect } from 'react-redux';
import ShowSchedulePeriod from '../components/ShowSchedulePeriod';

export class ShowSchedulePeriodContainer extends React.Component {

  render() {
    return <ShowSchedulePeriod />;
  }
}

const mapStateToProps = (state) => ({});

export default connect(mapStateToProps)(ShowSchedulePeriodContainer);
