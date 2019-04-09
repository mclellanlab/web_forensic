
function drawHeatmap(task_id, object_id) {
  d3.json('/heatmap_data/' + task_id, function(error, data){
    let species = ["Bacteroidales", "Clostridiales"];

    for (let key in data) {
      data[key] = JSON.parse(data[key]);
    }

    let sample_names = d3.map(data[species[0]], function(d){return d.sample_name;}).keys();
    let gridSize = 28;

    var colorScale = d3.scale.linear()
      .domain([0, 1])
      .range(["#FFFFFF", "#9E0142"]);

    var svg = d3.select(object_id).append("svg")
      .attr("width", 800)
      .attr("height", 180 + gridSize * sample_names.length)
      .append("g")
      .attr("transform", "translate(150,100)");

    var linearGradient = svg.append("defs")
      .append("linearGradient")
      .attr("id", "linear-gradient");

    linearGradient.append("stop")
      .attr("offset", "0%")
      .attr("stop-color", colorScale(0));

    linearGradient.append("stop")
      .attr("offset", "100%")
      .attr("stop-color", colorScale(1));

    let legend = svg.append("g")
      .attr("transform", "translate(390,"+ ((gridSize * sample_names.length)+30) +")");
    
    legend.append("rect")
      .attr("x", 0)
      .attr("y", 0)
      .attr("width", 160)
      .attr("height", 20)
      .style("stroke", "black")
      .style("stroke-width", 1)
      .style("fill", "url(#linear-gradient)");

    legend.append("text")
      .text("0")
      .attr("x", 0)
      .attr("y", 35)
      .attr("fill", "#000000")
      .style("font-size", "14px")
      .style("text-anchor", "middle");

    legend.append("text")
      .text("1")
      .attr("x", 160)
      .attr("y", 35)
      .attr("fill", "#000000")
      .style("font-size", "14px")
      .style("text-anchor", "middle");

    for (let order=0; order < species.length; order++) {
        let specie = species[order];
        let sample_types = d3.map(data[specie], function(d){return d.variable;}).keys();

        let offset = order * 300;

        var title = svg.append("g")
          .append("text")
          .text(specie)
          .attr('class', 'heatmap-title')
          .attr("x", offset + 75)
          .attr("y", -55)
          .attr("fill", "#000000")
          .style("font-size", "18px");

        var yLabels = svg.selectAll(".yLabel"+order)
          .data(sample_names)
          .enter().append("text")
            .text(function (d) { return d; })
            .attr("x", 0)
            .attr("y", function (d, i) { return i * gridSize; })
            .style("text-anchor", "end")
            .attr("transform", "translate(-6," + gridSize / 1.5 + ")")
            .attr("class", "xLabel mono axis");

        var xLabels = svg.selectAll(".xLabel"+order)
          .data(sample_types)
          .enter().append("text")
            .text(function(d) { return d; })
            .attr("x", function(d, i) { return offset + i * gridSize + gridSize * 0.5; })
            .attr("y", -5)
            .style("text-anchor", "right")
            .attr("transform-origin", function (d,i) {return (offset + i * gridSize + gridSize * 0.5)+"px -5px"})
            .attr("transform", function(d,i) { return  "rotate(-45)"})
            .attr("class", "yLabel mono axis");

        var heatMap = svg.selectAll(".heatmapbox"+order)
          .data(data[specie])
          .enter().append("rect")
          .attr("x", function(d) { return offset + sample_types.indexOf(d.variable) * gridSize; })
          .attr("y", function(d) { return sample_names.indexOf(d.sample_name) * gridSize; })
          .attr("rx", 4)
          .attr("ry", 4)
          .attr("class", "hour bordered")
          .attr("width", gridSize)
          .attr("height", gridSize)
          .style("fill", function (d) { return colorScale(d.value); });

        heatMap.style("fill", function(d) { return colorScale(d.value); });

        heatMap.append("svg:title").text(function(d) { return d.value; });
    }
  });
}