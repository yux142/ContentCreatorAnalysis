// set the dimensions and margins of the graph
var margin = {top: 10, right: 30, bottom: 30, left: 60},
    width = 660 - margin.left - margin.right,
    height = 400 - margin.top - margin.bottom;

// append the svg object to the body of the page
var svg = d3.select("#my_dataviz")
  .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform",
          "translate(" + margin.left + "," + margin.top + ")");


// var rowConverter = function (d) {
//   return {
//     log_date_month: d.log_date_month,
//     fans_level: d.fans_level,
//     fans_label: d.fans_label,
//     all_rel_cnt: +d.all_rel_cnt,
//     play_mid_cnt: +d.play_mid_cnt,
//     up_cnt: +d.up_cnt,
//     play_tran_fans: +d.play_tran_fans
//     }
// }; 


//Read the data
d3.csv("https://raw.githubusercontent.com/yux142/ContentCreatorAnalysis/main/data_cleaned/play_conversion.csv").then(function(data) {

    var allGroup = ["100k+","10k-100k","1k-10k","100-1k","0-100"];
    var parseTime = d3.timeParse("%Y/%m/%d");

    data.forEach(function(d) {
      d.log_date_month = parseTime(d.log_date_month);
    });


    // add the options to the button
    d3.select("#selectButton")
      .selectAll('myOptions')
     	.data(allGroup)
      .enter()
    	.append('option')
      .text(function (d) { return d; }) // text showed in the menu
      .attr("value", function (d) { return d; }); // corresponding value returned by the button

    // A color scale: one color for each group
    var myColor = d3.scaleOrdinal()
      .domain(allGroup)
      .range(d3.schemeSet2);

    // Add X axis --> it is a date format
    var x = d3.scaleTime()
      .domain([d3.min(data, function(d) { return d.log_date_month; }), d3.max(data, function(d) { return d.log_date_month; })])
      .range([ 0, width ]);
    svg.append("g")
      .attr("transform", "translate(0," + height + ")")
      .call(d3.axisBottom(x));

    // Add Y axis
    var y = d3.scaleLinear()
      .domain([0, d3.max(data, function(d) { return +d.play_tran_fans; })])
      .range([ height, 0 ]);
    svg.append("g")
      .call(d3.axisLeft(y));

    // Initialize line with first group of the list
    var line = svg
      .append('g')
      .append("path")
        .datum(data.filter(function(d){return d.fans_label==allGroup[0]}))
        .attr("d", d3.line()
          .x(function(d) { return x(d.log_date_month) })
          .y(function(d) { return y(+d.play_tran_fans) })
        )
        .attr("stroke", function(d){ return myColor("valueA") })
        .style("stroke-width", 4)
        .style("fill", "none")

    // A function that update the chart
    function update(selectedGroup) {

      // Create new data with the selection?
      var dataFilter = data.filter(function(d){return d.fans_label==selectedGroup})

      // Give these new data to update line
      line
          .datum(dataFilter)
          .transition()
          .duration(1000)
          .attr("d", d3.line()
            .x(function(d) { return x(d.log_date_month) })
            .y(function(d) { return y(+d.play_tran_fans) })
          )
          .attr("stroke", function(d){ return myColor(selectedGroup) })
    }

    // When the button is changed, run the updateChart function
    d3.select("#selectButton").on("change", function(d) {
        // recover the option that has been chosen
        var selectedOption = d3.select(this).property("value")
        // run the updateChart function with this selected option
        update(selectedOption)
    })

})
