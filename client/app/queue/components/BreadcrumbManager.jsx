import React from 'react';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import Breadcrumbs from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Breadcrumbs';

const breadcrumbStyling = css({
  marginTop: '-1.5rem',
  marginBottom: '-1.5rem'
});

class BreadcrumbManager extends React.Component {
  render = () => <Breadcrumbs
    renderAllCrumbs
    getBreadcrumbLabel={(route) => route.breadcrumb}
    shouldDrawCaretBeforeFirstCrumb={false}
    styling={breadcrumbStyling}
    elements={this.props.breadcrumbs}
  />
}

const mapStateToProps = (state) => _.pick(state.queue.ui, 'breadcrumbs');

export default connect(mapStateToProps)(BreadcrumbManager);
