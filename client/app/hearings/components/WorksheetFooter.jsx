import React from 'react';
import { connect } from 'react-redux';

class WorksheetFooter extends React.PureComponent {

  render() {
    const {
      veteranName
    } = this.props;

    return <div className="cf-print-footer">
      <div className="cf-push-right">
        {veteranName},
        <span className="cf-print-number" />
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  veteranName: state.worksheet.veteran_fi_last_formatted
});

export default connect(
  mapStateToProps
)(WorksheetFooter);
