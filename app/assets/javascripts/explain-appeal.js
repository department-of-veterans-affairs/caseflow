//= require vis-timeline/dist/vis-timeline-graph2d.min.js

/**
 * Support code for app/views/explain/show.html.erb,
 * associated with app/controllers/explain_controller.rb.
 * Also see accompanying app/assets/stylesheets/explain_appeal.css.
 * These are added to the application in config/initializers/assets.rb.
 */

const taskNodeColor = {
  assigned: "#00dd00",
  in_progress: "#00ff00",
  on_hold: "#cccc00",
  cancelled: "#8a8",
  completed: "#00bb00"
}

const itemDecoration = {
  tasks: { style: (item)=>"background-color: "+taskNodeColor[item.status] }
};

function decorateTimelineItems(items){
  items.forEach(item => {
    if(!itemDecoration.hasOwnProperty(item.tableName)) return;
    for ([key, value] of Object.entries(itemDecoration[item.tableName])) {
      if (typeof value === 'function') {
        value = value(item)
      }
      item[key] = value
    }
  });
  // console.log(items)
  return items;
}

function addTimeline(elementId, timeline_data){
  const timeline = document.getElementById(elementId);
  const items = new vis.DataSet(decorateTimelineItems(timeline_data));
  const timeline_options = {
    width: '95%'
  };
  new vis.Timeline(timeline, items, timeline_options);
}
