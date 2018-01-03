# Voronoi Visualizer
Visual aid for understanding what voronoi diagrams are.
Powered by [Voronoi](https://github.com/CooperCorona/Voronoi).
Generate random voronoi diagrams or input your own points to create a custom voronoi diagram.

### New Features
* Click anywhere in the diagram to add a new point.
* Drag a point to watch the diagram update in real time (only functions for diagrams with <= 64 points because diagrams with higher number of points take too long to render).
* Mono Mode Update: You can now choose any number and type of colors to color your Voronoi Diagram (Mono is now the only coloring scheme; others have been deprecated).

![](VoronoiDiagramImage.png)

## Exporting
[This script](https://gist.github.com/CooperCorona/ef7b9884439f98c2f6bc6c87aec9d46f) automatically manages dependencies and exports VoronoiVisualizer as a Mac application. This way, you can run it independent of Xcode.

* Open Terminal
* Navigate to the directory you want to place the repositories in
* Run ```mkdir VoronoiVisualizer; cd VoronoiVisualizer; curl https://gist.githubusercontent.com/CooperCorona/ef7b9884439f98c2f6bc6c87aec9d46f/raw/f71d806a6f3e24854c27dff17fafb3210c145048/exportVoronoi.sh > exportVoronoi.sh; chmod 700 exportVoronoi.sh; ./exportVoronoi.sh```
* Whenever you want to update and re-export the app, navigate to the directory and run ```./exportVoronoi.sh```
