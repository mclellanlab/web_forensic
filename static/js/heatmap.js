
function drawHeatmap(target, task_id, object_id) {
    d3.json('/heatmap_data/' + target + '/' + task_id, function(error, data){

    let sample_names = d3.map(data, function(d){return d.sample_name;}).keys();
    let sample_types = d3.map(data, function(d){return d.variable;}).keys();

    let margin = { top: 60, right: 50, bottom: 50, left: 240 };
    let gridSize = 36;

    let width = 800;
    let height = margin.top + margin.bottom + (gridSize * sample_names.length);

    console.log(sample_names, sample_types);

    var colorScale = d3.scale.linear()
            .domain([0, 1])
            .range(["#FFFFFF", "#FF0000"]);

    var svg = d3.select(object_id).append("svg")
            .attr("width", width)
            .attr("height", height)
            .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

          var yLabels = svg.selectAll(".xLabel")
              .data(sample_names)
              .enter().append("text")
                .text(function (d) { return d; })
                .attr("x", 0)
                .attr("y", function (d, i) { return i * gridSize; })
                .style("text-anchor", "end")
                .attr("transform", "translate(-6," + gridSize / 1.5 + ")")
                .attr("class", "xLabel mono axis");

          var xLabels = svg.selectAll(".yLabel")
              .data(sample_types)
              .enter().append("text")
                .text(function(d) { return d; })
                .attr("x", function(d, i) { return i * gridSize + gridSize * 0.5; })
                .attr("y", -5)
                .style("text-anchor", "right")
                .attr("transform-origin", function (d,i) {return (i * gridSize + gridSize * 0.5)+"px -5px"})
                .attr("transform", function(d,i) { return  "rotate(-45)"})
                .attr("class", "yLabel mono axis");

          var heatMap = svg.selectAll(".heatmapbox")
              .data(data)
              .enter().append("rect")
              .attr("x", function(d) { return sample_types.indexOf(d.variable) * gridSize; })
              .attr("y", function(d) { return sample_names.indexOf(d.sample_name) * gridSize; })
              .attr("rx", 4)
              .attr("ry", 4)
              .attr("class", "hour bordered")
              .attr("width", gridSize)
              .attr("height", gridSize)
              .style("fill", function (d) { return colorScale(d.value); });

          heatMap.style("fill", function(d) { return colorScale(d.value); });

          heatMap.append("svg:title").text(function(d) { return d.value; });
});
}