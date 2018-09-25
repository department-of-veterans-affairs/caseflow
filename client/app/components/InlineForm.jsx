import React, { Children } from 'react';

export default function InlineForm({ children }) {

  return (<div className="usa-width-one-half cf-inline-form">
    {Children.map(children, (child) => {
      return (<div className="cf-push-left">
        {child}
      </div>);
    })}
  </div>);
}
