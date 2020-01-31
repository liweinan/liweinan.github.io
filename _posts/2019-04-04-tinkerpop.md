---
title: tinkerpop的使用（中）
abstract: 这是本系列文章的第二篇，介绍如何使用jupyter-notebook操作图数据库。
---

## {{ page.title }}

这是本系列文章的第二篇，介绍如何使用`jupyter-notebook`操作图数据库。

上一篇文章里，我们下载并安装了`tinkerpop`的`gremlin-server`和`gremlin-console`，启动了`gremlin-server`服务，并且通过`gremlin-console`连接到了server并导入了样例数据。

接下来就是使用数据，因为`gremlin-console`默认使用的是`groovy`语言，可能使用起来对于大多数人不那么方便，所以这篇文章介绍`gremlinpython`的使用方法。

`gremlinpython`是`tinkerpop`项目提供的一个基于python的客户端，用于跟服务端进行交互。这样用户就可以使用python语言读取图数据库里的数据，并且进行数据查询了。有了这个组件，我们就可以在`jupyter-notebook`里面很方便地撰写相关代码。

为了使用`gremlinpython`，首先是用`pip`安装这个组件：

```bash
$ pip install gremlinpython
```

安装完成后，启动jupyter：

```bash
$ jupyter-notebook
```

启动完成后，可以试试看导入`gremlinpython`的相关classes：

```python
from gremlin_python.driver.driver_remote_connection import DriverRemoteConnection
from gremlin_python.structure.graph import Graph
```

引入相关classes以后，可以连接服务端试试看：

```python
graph = Graph()
g = graph.traversal().withRemote(DriverRemoteConnection('ws://localhost:8182/gremlin', 'g'))
```

连接完成以后，可以试试读取数据并做一些查询：

```python
hkVertexId = g.V().has('airport', 'code', 'HKG').id().next()
```

```python
sydneyVertexId = g.V().hasLabel('airport').has('code', 'SYD').id().next()
```

以上代码的运行结果如下：

![](https://raw.githubusercontent.com/liweinan/blogpic2019/master/data/apr04/5C360420-6DFE-4C8B-BD7A-7F64615D009C.png)

可以看到，我们在`jupyter-book`里面调用了`gremlinpython`的api，完成了对`gremlin-server`当中数据的查询。这样的工作流比较直观方便。

上面的notebook，我放在了这里：

* [gremlin-notebooks/intro.ipynb at master · liweinan/gremlin-notebooks · GitHub](https://github.com/liweinan/gremlin-notebooks/blob/master/intro.ipynb)

有兴趣的小伙伴可以看下。

以上是对`gremlinpython`的一个简单介绍，更多的使用方法可以查看它的文档：

* [http://tinkerpop.apache.org/docs/current/reference/#gremlin-python](http://tinkerpop.apache.org/docs/current/reference/#gremlin-python) 

此外，还可以查看这个项目里面各种`jupyter-notebook`的例子：

* [https://github.com/AndrewChau/learn-gremlin-jupyter-notebook/tree/master/Gremlin%20Notebooks](https://github.com/AndrewChau/learn-gremlin-jupyter-notebook/tree/master/Gremlin%20Notebooks) 

上面这个项目里的例子基于这套电子教程：

* [https://github.com/krlawrence/graph](https://github.com/krlawrence/graph) 

可以用来系统学习。

这篇文章介绍了`gremlinpython`和`jupyter-notebook`的联合使用，下一篇文章最后介绍下`gremlinpython`在`pycharm`当中的使用。


