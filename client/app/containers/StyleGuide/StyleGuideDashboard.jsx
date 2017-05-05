import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

let StyleGuideDashboard = () => {

  return (
    <div>
    <StyleGuideComponentTitle
      title="Dashboard"
      id="dashboard"
      link="-efolder/blob/master/app/views/stats/show.html.erb"
      isExternalLink={true}
    />
    <p>
      Each Caseflow application has a business dashboard to help the team and our
      stakeholders track the performance of the application. Metrics specific to
      the application are determined by the team before the dashboard is built.
      These metrics often include basic usage numbers, time to complete task metrics,
      success rates, and more.
    </p>

    <p>
      Dashboards are featured on the standard App Canvas. Data is broken up by tabs
      so the user can view data by hours, days, weeks, or months.
    </p>
    <p>
      Each data point has includes the metric title and quantity for the selected
      time period. It also has a chart displaying historical data for that same data
      point.
    </p>
    <p>Users can hover over historical points on the chart to show the data point
      for that specific time.</p>
  </div>

  );
};

export default StyleGuideDashboard;
