---
title: A Java Implementation of Dijkstra's Algorithm
---

I'm reading the book _Grokking Algorithm_ recently, and it introduces _Dijkstra's Algorithm_ in chapter 7. Here is a java implementation I've written:

```java
import java.util.*;

/**
 * Created by weli on 26/02/2017.
 */
public class Graph {

    class Edge {
        private String from;
        private String to;
        private int weight;

        public String getFrom() {
            return from;
        }

        public String getTo() {
            return to;
        }

        public int getWeight() {
            return weight;
        }

        public Edge(String from, String to, int weight) {
            this.from = from;
            this.to = to;
            this.weight = weight;
        }

        @Override
        public String toString() {
            return "{" + from + "->" + to + " / " + weight + "}";
        }
    }

    private List<Edge> edges = new ArrayList<>();
    private Set<String> nodes = new HashSet<>();
    private Map<String, String> path = new HashMap<>(); // to -> from
    private Map<String, Integer> costs = new HashMap<>();

    private List<String> processed = new ArrayList<>();

    private String start = "start";
    private String fin = "fin";

    {
        processed.add(start);
        processed.add(fin);
    }

    public String getStart() {
        return start;
    }

    public String getFin() {
        return fin;
    }

    public void addEdge(String from, String to, int weight) {
        edges.add(new Edge(from, to, weight));
        nodes.add(from);
        nodes.add(to);

        if (from.equals(start)) {
            costs.put(to, weight);
        } else if (costs.get(to) == null) {
            costs.put(to, Integer.MAX_VALUE);
        }
    }

    private String nextCheapestNode() {
        if (nodes.size() == processed.size()) // all nodes are processed
            return null;

        int cheapest = Integer.MAX_VALUE;
        String cheapestNode = null;

        for (Map.Entry<String, Integer> cost : costs.entrySet()) {
            System.out.println("Updated cost:" + cost);
            if (cost.getValue() <= cheapest && !processed.contains(cost.getKey())) {
                cheapest = cost.getValue();
                cheapestNode = cost.getKey();
            }
        }
        System.out.println("next cheapest: " + cheapestNode);
        return cheapestNode;
    }

    public void dijkstra() {
        System.out.println("Initial costs: " + costs);

        String node = nextCheapestNode();

        path.put(node, start);
        while (node != null) {
            int cost = costs.get(node);
            Set<Edge> neighbors = findNeighbors(node);
            for (Edge neighbor : neighbors) {
                int newCost = cost + neighbor.getWeight();
                if (costs.get(neighbor.getTo()) > newCost) {
                    costs.put(neighbor.getTo(), newCost);
                    path.put(neighbor.getTo(), neighbor.getFrom());
                }
            }
            processed.add(node);
            node = nextCheapestNode();
        }
    }

    private String generatePath() {
        StringBuffer result = new StringBuffer();
        String next = null;
        for (Map.Entry<String, String> p : path.entrySet()) {
            if (p.getKey().equals(fin)) {
                result.append(p.getKey()).append(" <- ");
                next = p.getValue();
            }
        }

        while (next != null) {
            for (Map.Entry<String, String> p : path.entrySet()) {
                if (p.getKey().equals(next)) {
                    result.append(p.getKey()).append(" <- ");
                    next = p.getValue();
                    if (next.equals(start)) {
                        result.append(start);
                        next = null;
                    }
                }
            }
        }

        return result.toString();
    }

    private Set<Edge> findNeighbors(String node) {
        Set<Edge> neighbors = new HashSet<>();
        for (Edge edge : edges) {
            if (edge.getFrom().equals(node)) {
                neighbors.add(edge);
            }
        }
        return neighbors;
    }

    @Override
    public String toString() {
        return "Graph{" +
                "edges=" + edges +
                '}';
    }

    public Map<String, String> getPath() {
        return path;
    }

    public static void main(String[] args) throws Exception {

        Graph g = new Graph();
        g.addEdge("start", "a", 1);
        g.addEdge("start", "b", 1);
        g.addEdge("a", "b", 1);
        g.addEdge("b", "c", 1);
        g.addEdge("a", "c", 1);
        g.addEdge("c", "fin", 1);
        g.addEdge("b", "fin", 1);
        System.out.println(g);

        g.dijkstra();
        System.out.println(g.getPath());
        System.out.println(g.generatePath());
    }
}
```

I'll introduce the above implementation in this article. Firstly, the usage is like this:

```java
 public static void main(String[] args) throws Exception {

        Graph g = new Graph();
        g.addEdge("start", "a", 1);
        g.addEdge("start", "b", 1);
        g.addEdge("a", "b", 1);
        g.addEdge("b", "c", 1);
        g.addEdge("a", "c", 1);
        g.addEdge("c", "fin", 1);
        g.addEdge("b", "fin", 1);
        System.out.println(g);

        g.dijkstra();
        System.out.println(g.getPath());
        System.out.println(g.generatePath());
}
```

The above code created a `Graph` class, and added _edges_ into the _graph_, and then the `dijkstra()` method is executed to calculate the _cheapest path_. Here is the execution result:

```
Graph{edges=[{start->a / 1}, {start->b / 1}, {a->b / 1}, {b->c / 1}, {a->c / 1}, {c->fin / 1}, {b->fin / 1}]}
Initial costs: {a=1, b=1, c=2147483647, fin=2147483647}
Updated cost:a=1
Updated cost:b=1
Updated cost:c=2147483647
Updated cost:fin=2147483647
next cheapest: b
Updated cost:a=1
Updated cost:b=1
Updated cost:c=2
Updated cost:fin=2
next cheapest: a
Updated cost:a=1
Updated cost:b=1
Updated cost:c=2
Updated cost:fin=2
next cheapest: c
{b=start, c=b, fin=b}
fin <- b <- start
```

We can see how the path costs are updated in each iteration, and how the final path is calculated at last. Here is the class diagram:

![Class Diagram]({{ site.url }}/assets/dig-class.png)

The `Graph` class is to store the structure _DAG_, of which the full name is _Directed Acyclic Graph_. The `Graph` contains a lot of _edges_, so the `Edge` class is to represent the structure.

Here are the attributes in `Edge` class:

```java
class Edge {
    private String from;
    private String to;
    private int weight;
}
```

`from : String` and `to : String` are two nodes of connected by the edge. We use `String` as node class. This is okay because we don't allow different nodes to have same name. The `weight` attribute is straight-forward and it stores the weight of this edge for calculation. Because `Graph` contains many _edges_, so in `Graph` class, we store these edges like this:

```java
private List<Edge> edges = new ArrayList<>();
```

We also need to store all the _nodes_ in graph for later calculation:

```java
private Set<String> nodes = new HashSet<>();
```

Please note we use `Set<String>` to store the `nodes`, because `Set` type will not store entries with same value. This can ensure no duplicated nodes will appear in the data structure. The next important data structure is the _cost table_:

```java
private Map<String, Integer> costs = new HashMap<>();
```

This table stores the _weight sum_ from the start point to the target node. During calculation process, this table will be keep updated.

Another important thing is that we use `Map<String, Integer>` type to store the `node <-> weight sum` pair，because the `Map` type is simliar to the `Set` type, it won't accept duplicate `key` value, which means it won't contain multiple entries for same _node_. If we put a `String <-> Integer` pair with an existing `String` value in `Map`, it will just update the existing entry. That is just what we need: to update the `node <-> weight sum` entry with new value.

We also need to mark the _start node_ and the _end node_ of a graph, and here are the relative attributes in `Graph` class:

```java
private String start = "start";
private String fin = "fin";
```

We can compare the node name in calculation process to check if it is start or end point. Now let us check the methods in `Graph`:

```java
public void addEdge(String from, String to, int weight) {
    edges.add(new Edge(from, to, weight));
    nodes.add(from);
    nodes.add(to);

    if (from.equals(start)) {
        costs.put(to, weight);
    } else if (costs.get(to) == null) {
        costs.put(to, Integer.MAX_VALUE);
    }
}
```

The purpose of above method is to add an _edge_ into _graph_:

```java
edges.add(new Edge(from, to, weight));
```

And also add the two nodes of the edge into `nodes` set:

```java
nodes.add(from);
nodes.add(to);
```

We do not need to worry that we will add duplicate nodes into `nodes` set, because the type of `nodes` is `Set`, it does not contain duplicate entries with same value. Adding the `String` with same value will just overwrite the existing one. The next important task of `addEdge` is to update the `costs` table:

```java
if (from.equals(start)) {
    costs.put(to, weight);
} else if (costs.get(to) == null) {
    costs.put(to, Integer.MAX_VALUE);
}
```

注意这里我们要分两种情况考虑：如果这条边是和`start`相连，那么这条边的另一头的`node`就是起始要进行最小`weight`计算的，所以我们要把真实的`weight`加到`costs`这张表中，用于初始的路径权重计算。

如果不是和起始节点相连的边，那么两头的节点的权重不应该做为一开始计算考虑的范围，所以设为`Integer.MAX_VALUE`就可以了。这样算法因为是寻找`最小权重`的下一个节点，所以这些节点肯定不会被选上。

注意这里：

```java
else if (costs.get(to) == null)
```

这里面要判断一下当前节点在`costs`表中是否已经有权重了，以免被新的值覆盖。为什么？因为和起点相连的边上的节点，可能还和别的边相连，如果这个节点的权重值被覆盖，逻辑就错了。比如这幅图：

![Graph]({{ site.url }}/assets/dij01.png)

如上图所示，我们可以看到`b`是和`start`相连，同时也和`c`相连，`b`的初始权值在`costs`表里面应该是`1`，所以`b->c`这条边在处理时，`b`的权值不应该被覆盖为`Integer.MAX_VALUE`。算法里面这些细节和边界条件其实是挺磨人的，但写实现就是要注意到这些。

『阿男导读』＊Grokking Algorithm＊

接下来看`nextCheapestNode()`这个方法：

```
private String nextCheapestNode() {
    if (nodes.size() == processed.size()) // all nodes are processed
        return null;

    int cheapest = Integer.MAX_VALUE;
    String cheapestNode = null;

    for (Map.Entry<String, Integer> cost : costs.entrySet()) {
        System.out.println("Updated cost:" + cost);
        if (cost.getValue() <= cheapest && !processed.contains(cost.getKey())) {
            cheapest = cost.getValue();
            cheapestNode = cost.getKey();
        }
    }
    System.out.println("next cheapest: " + cheapestNode);
    return cheapestNode;
}
```

这个方法的目的就是寻找下一个还未计算过的权值最低的节点，核心逻辑是这里：

```
if (cost.getValue() <= cheapest && !processed.contains(cost.getKey()))
```

这个逻辑和书里面介绍的算法是一模一样的，大家对照看就可以。

这个方面里面需要注意的是一开始的一个结束状态的判断：

```
if (nodes.size() == processed.size()) // all nodes are processed
    return null;
```

如果所有的`nodes`都在`processed`列表里面了，算法的计算也就结束了。为了支撑这个逻辑，我们要创建一个`processed`列表：

```
private List<String> processed = new ArrayList<>();
```

然后在`Graph`创建的时候，要初始化这个列表：

```
{
    processed.add(start);
    processed.add(fin);
}
```

如上所示，把起点和终点都加进来，因为这两个节点不需要计算权重。阿男一直觉得，算法的一些边界条件，和细节处理是在实现的时候最需要想明白，写对的地方。这些地方不属于算法的主体，但是如果写错了，调试起来特别困难。

『阿男导读』＊Grokking Algorithm＊

接下来是算法的入口函数：

```
public void dijkstra() {
    System.out.println("Initial costs: " + costs);

    String node = nextCheapestNode();

    path.put(node, start);
    while (node != null) {
        int cost = costs.get(node);
        Set<Edge> neighbors = findNeighbors(node);
        for (Edge neighbor : neighbors) {
            int newCost = cost + neighbor.getWeight();
            if (costs.get(neighbor.getTo()) > newCost) {
                costs.put(neighbor.getTo(), newCost);
                path.put(neighbor.getTo(), neighbor.getFrom());
            }
        }
        processed.add(node);
        node = nextCheapestNode();
    }
}
```

这个函数就是首先找到初始要计算的节点：

```
String node = nextCheapestNode();
```

然后进入主循环逻辑：

```
while (node != null)
```

找到每一个节点的`neighbors`，在`costs`表格里面不断更新它们的权值之和。注意这里还有一个`path`数据：

```
private Map<String, String> path = new HashMap<>(); // to -> from
```

这个是我们实际上最后得到的路径结果，注意最后的路径是从结尾到起始点反推出来的，所以在书中这个数据叫做`parents`表格。具体原因当然是因为算法本身的计算过程决定的。

『阿男导读』＊Grokking Algorithm＊

最后我们来看使用，以下是建立一个书中所讲的`DAG`：

```
Graph g = new Graph();
g.addEdge("start", "a", 1);
g.addEdge("start", "b", 1);
g.addEdge("a", "b", 1);
g.addEdge("b", "c", 1);
g.addEdge("a", "c", 1);
g.addEdge("c", "fin", 1);
g.addEdge("b", "fin", 1);
```

上面这个过程就是建立这个图的数据：

![Graph]({{ site.url }}/assets/dij02.png)

执行最优路径计算的入口：

```
g.dijkstra();
```

打印出路径计算结果：

```
System.out.println(g.generatePath());
```

为什么我们不可以直接查看`path`这个数据，还要一个`generatePath()`方法？因为在路径计算的时候，我们是不断更新一个节点更优的`parent`的，那么最后`path`列表里面肯定会有最重被舍弃掉的`死路`，这些`死路`的终点之前是`parent`，但后来被优化掉了。

但是没关系，我们最终计算得到路径后，从path的数据结构里面，从终点的`parent`反推回起点就可以了，而`generatePath`就是做这件事的：

```
private String generatePath() {
	StringBuffer result = new StringBuffer();
	String next = null;
	for (Map.Entry<String, String> p : path.entrySet()) {
	    if (p.getKey().equals(fin)) {
	        result.append(p.getKey()).append(" <- ");
	        next = p.getValue();
	    }
	}

	while (next != null) {
	    for (Map.Entry<String, String> p : path.entrySet()) {
	        if (p.getKey().equals(next)) {
	            result.append(p.getKey()).append(" <- ");
	            next = p.getValue();
	            if (next.equals(start)) {
	                result.append(start);
	                next = null;
	            }
	        }
	    }
	}

	return result.toString();
}
```

这个函数的逻辑就是先从`path`里面找到终点，打印出来，然后再从终点一路反推回起点。这个函数改造一下就可以不是用来打印，而是清理出来一条完整的路径数据，留给大家自己玩。

最后我们看代码执行结果：

```
Updated cost:fin=2
fin <- b <- start
```

最优路径就是通过`b`直接到终点，`cost`是`2`。接下来我们改改路径的权重：

```
g.addEdge("start", "a", 1);
g.addEdge("start", "b", 10);
g.addEdge("a", "b", 1);
g.addEdge("b", "c", 1);
g.addEdge("a", "c", 1);
g.addEdge("c", "fin", 1);
g.addEdge("b", "fin", 10);
```

图变成了这样：

![Graph]({{ site.url }}/assets/dij03.png)

我们可以看到，`start -> b`和`b -> c`的代价变大了，那么最优路径应该是`start -> a -> c -> fin`，执行代码看看是不是这样：

```
Updated cost:fin=3
fin <- c <- a <- start
```

和预期的一样，只不过我们是从终点反推起点，把它处理成起点到终点也不是难事。

这章花了很多功夫，总算给大家讲完了。大家也可以花些时间，把这章这个算法搞明白。图论是很有趣的领域，值得细细研究。
