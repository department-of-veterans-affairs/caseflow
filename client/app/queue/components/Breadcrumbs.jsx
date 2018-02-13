import React from 'react';
import PropTypes from 'prop-types';
import { Route } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import _ from 'lodash';

export default class Breadcrumbs extends React.PureComponent {
  render = () => {
    const { crumbs, styling } = this.props
    const breadcrumbComponents = _.sortBy(crumbs, ({ path }) => path.length).
      map((route, idx, crumbs) =>
        <Route key={route.label} path={route.path} render={(props) =>
          <React.Fragment>
            <Link id="cf-logo-link" to={props.match.url} classNames={['cf-btn-link']}>
              {route.label}
            </Link>
            {idx + 1 < crumbs.length && <React.Fragment>&nbsp;&nbsp;&gt;&nbsp;&nbsp;</React.Fragment>}
          </React.Fragment>
        } />
      );

    return <div {...styling}>{breadcrumbComponents}</div>;
  };
}

Breadcrumbs.propTypes = {
  crumbs: PropTypes.arrayOf(PropTypes.shape({
    path: PropTypes.string,
    label: PropTypes.string
  })).isRequired,
  styling: PropTypes.object
};
