import React from 'react';
import Link from './Link';
import { Route } from 'react-router-dom';

const getElementsWithBreadcrumbs = (element) => {
  if (!element.props.children) {
    return [];
  }

  return React.Children.toArray(element.props.children).reduce((acc, child) => {
    if (child.props.breadcrumb) {
      return [...acc, {
        path: child.props.path,
        breadcrumb: child.props.breadcrumb
      }];
    }

    return [...acc, ...getElementsWithBreadcrumbs(child)];
  }, []);
};

export default class Breadcrumbs extends React.Component {
  render() {
    const breadcrumbComponents = getElementsWithBreadcrumbs(this).map(
    (route) => <Route path={route.path} render={
      (props) => <span>
          <h2 id="page-title" className="cf-application-title">&nbsp; > &nbsp;</h2>
          <Link id="cf-logo-link" to={props.match.url}>
            <h2 id="page-title" className="cf-application-title">{route.breadcrumb}</h2>
          </Link>
        </span>
      } />
    );

    return <span>{breadcrumbComponents}</span>;
  }
}
