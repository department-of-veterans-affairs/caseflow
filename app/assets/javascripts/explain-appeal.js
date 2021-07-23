//= require vis-timeline/dist/vis-timeline-graph2d.min.js
//= require vis-network/dist/vis-network.min.js

// Example timeline visualizations: https://visjs.github.io/vis-timeline/examples/timeline/

/**
 * Support code for app/views/explain/show.html.erb,
 * associated with app/controllers/explain_controller.rb.
 * Also see accompanying app/assets/stylesheets/explain_appeal.css.
 * These are added to the application in config/initializers/assets.rb.
 */

//================== Timeline visualization ========================

const items = new vis.DataSet();

// called from app/views/explain/show.html.erb
function addTimeline(elementId, timeline_data){
  items.add(decorateTimelineItems(timeline_data));
  const startDates = items.get({fields: ['start']}).map((str)=> new Date(str.start));
  const endDates = items.get({fields: ['end']}).map((str)=> new Date(str.end));
  const millisInAMonth = 1000*60*60*24*30 // an approximate month in milliseconds
  const timeline_options = {
    width: '95%',
    // maxHeight: 800,
    horizontalScroll: true,
    verticalScroll: true,
    min: new Date(Math.min(...startDates) - millisInAMonth*6), // add extra time so that entire label is visible
    max: new Date(Math.min(Math.max(...endDates), new Date()) + millisInAMonth*12), // add exta time so that labels are visible
    zoomMin: 1000 * 60 * 60, // 1 hour in milliseconds
    orientation: {axis: 'both'},  // show time axis on both the top and bottom
    stack: true,
    zoomKey: 'ctrlKey',
    order: (a, b) => b.record.id - a.record.id,
    tooltip: {
      followMouse: true
    }
  };
  const timelineElement = document.getElementById(elementId);
  const groups = groupEventItems(timeline_data);

  return new vis.Timeline(timelineElement, items, groups, timeline_options);
}

const itemDecoration = {
  tasks: {
    className: (item)=> item.className + " task_" + item.status
  },
  hearings: {
    className: (item)=> item.className + " hearing_" + item.status
  }
};

const formatJson = (obj) => {
  return JSON.stringify(obj, null, ' ').
    replace('{\n', '').
    replace('\n}', '');
};

// https://visjs.github.io/vis-timeline/docs/timeline/#items
function decorateTimelineItems(items){
  items.forEach(item => {
    item.className = item.record_type;

    if(itemDecoration.hasOwnProperty(item.table_name)){
      for ([key, value] of Object.entries(itemDecoration[item.table_name])) {
        item[key] = (typeof value === 'function') ? value(item) : value;
      }
    }

    // `item.title` is displayed as the tooltip
    if(!item.title){
      item.title = "<pre class='event_detail'>"+formatJson(item.record)+"</pre>";
    }
  });
  return items;
}

// https://visjs.github.io/vis-timeline/docs/timeline/#groups
var groups = new vis.DataSet();
function groupEventItems(items){
  groups.add({
      id: 'phase',
      content: 'phases',
      className: 'group_phase',
      order: 0,
  });
  groups.add({
      id: 'tasks',
      content: 'tasks',
      className: 'group_tasks',
      order: 1,
  });
  groups.add({
    id: 'cancelled_tasks',
    content: 'cancelled<br/> tasks',
    className: 'group_cancelled_tasks',
    order: 3,
  });
  groups.add({
    id: 'others',
    content: 'others',
    className: 'group_others',
    order: 9,
  });
  return groups;
}

function toggleTimelineEventGroup(checkbox){
  groups.update({id: checkbox.value, visible: checkbox.checked});
}

//================== Network graph ========================

// These colors should match with those in export-appeal.css
const taskNodeColor = {
  assigned: "#FFFF80",
  on_hold: "#A3A303",
  in_progress: "#00FF00",
  completed: "#00B800",
  cancelled: "#D89696"
}

// See icons at https://fontawesome.com/icons
const nodeDecoration = {
  intakes: { shape: "diamond" },
  cavc_remands: { shape: "triangle" },
  appeals: { shape: "star", size: 30, color: "blue" },
  claimants: { shape: "ellipse", color: "#d3d3d3" },
  veterans: { shape: "icon", icon: { code: "\uf29a" } },
  people: { shape: "icon", icon: { code: "\uf2bb", color: "gray" } },
  users: { shape: "icon", icon: { code: "\uf007", color: "gray" } },
  organizations: { shape: "icon", icon: { code: "\uf0e8", color: "#a3a3a3" } },
  tasks: { shape: "box", color: (node)=>taskNodeColor[node.status],
           shapeProperties: { borderRadius: 1 }
         },
  request_issues: { shape: "ellipse", color: "#ffa500" },
  decision_issues: { shape: "ellipse", color: "#ffe100" },
  decision_documents: { shape: "icon", icon: { code: "\uf15b", color: "#660000" } },
  attorney_case_reviews: { shape: "icon", icon: { code: "\uf07a", color: "#660033" } },
  judge_case_reviews: { shape: "icon", icon: { code: "\uf07a", color: "#660000" } }
};

// Using decorateNodes instead of CSS styles because the graph is in a canvas and
// the color is part of the shape and icon.
function decorateNodes(nodes){
  nodes.forEach(node => {
    if(!nodeDecoration.hasOwnProperty(node.tableName)) return;

    for ([key, value] of Object.entries(nodeDecoration[node.tableName])) {
      if (typeof value === 'function') {
        value = value(node)
      }
      node[key] = value
    }

    // `node.title` is displayed as the tooltip on node mouseover
    if(!node.title){
      node.title = formatJson(node);
    }
  });
  // console.log(nodes)
  return nodes;
}

const nodesFilterValues = {};

// Define filters needed to dynamically filter nodes from the network graph visualization.
const nodesFilter = (node) => {
  visible = nodesFilterValues[node.tableName];
  return visible === undefined ? true : visible
};
const edgesFilter = (edge) => {
  return true;
};

const nodesData = new vis.DataSet();
const edgesData = new vis.DataSet();

const nodesView = new vis.DataView(nodesData, { filter: nodesFilter });
const edgesView = new vis.DataView(edgesData, { filter: edgesFilter });

function addNetworkGraph(elementId, network_graph_data){
  nodesData.add(decorateNodes(network_graph_data["nodes"]));
  edgesData.add(network_graph_data["edges"])
  const network_options = {
    width: '95%',
    height: '500px',
    edges: {
      arrows: 'to'
    },
    interaction: {
      zoomSpeed: 0.2
    }
  };

  const netgraph = document.getElementById(elementId);
  return new vis.Network(netgraph, { nodes: nodesView, edges: edgesView }, network_options);
}

function toggleNodeType(checkbox){
  console.error("checkbox", checkbox);
  nodesFilterValues[checkbox.value] = checkbox.checked;
  nodesView.refresh();
}
