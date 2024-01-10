---
title: The JBeret Batch Partition Example
---

I have added an example to show the usage of JBeret as Batch API framework to run a partitioned step:

- [https://github.com/liweinan/jberet-playground/commit/01c21a6f3a10c38727fd27653d3d949304b91640](https://github.com/liweinan/jberet-playground/commit/01c21a6f3a10c38727fd27653d3d949304b91640)

The core part is to configure the partitions in the job descriptor file:

```xml
<partition>
    <plan partitions="2" threads="2">
        <properties partition="0">
            <property name="start" value="1"/>
            <property name="end" value="5"/>
        </properties>
        <properties partition="1">
            <property name="start" value="6"/>
            <property name="end" value="10"/>
        </properties>
    </plan>
</partition>
```

By default, the `threads` number and the `partitions` numbers are the same, but you can set the different numbers for them. Please note you must define each partition in the descriptor file, or during runtime the job will throw exceptions. The partitions are running in separate threads, and they are running concurrently so the running order of partitions is random.

The partition will provide two properties called `start` and `end`, and it can be used in the reader implementation to control how to read the data. The property can be injected into reader like this:

```xml
<reader ref="partitionedChunkReader">
    <properties>
        <property name="start" value="#{partitionPlan['start']}"/>
        <property name="end" value="#{partitionPlan['end']}"/>
    </properties>
</reader>
```

As the configuration shown above, the values can be read by the `partitionPlan` property. In the example, the `PartitionedChunkItemReader` class use the properties like this:

```java
public class PartitionedChunkItemReader extends AbstractItemReader {
    private Integer[] tokens;
    private Integer count;
    ...
    @Override
    public void open(Serializable checkpoint) throws Exception {
        System.out.println("START -> " + start);
        if (Integer.parseInt(start) == 1) {
            tokens = new Integer[]{1, 2, 3, 4, 5};
            count = 0;
        } else {
            tokens = new Integer[]{6, 7, 8, 9, 10};
            count = 0;
        }

    }

}
```

As the code shown above, the reader class uses the `start` property to split the data into two parts. The the different partitions will get the different data segment to process.

Here is the running result of the testing method `givenPartition_thenBatch_completesWithSuccess`:

```bash
...
START -> 1
START -> 6
processing item -> 1
processing item -> 6
processing item -> 7
processing item -> 8
processing item -> 2
processing item -> 3
items -> [1, 2, 3]
processing item -> 4
processing item -> 5
items -> [4, 5]
items -> [6, 7, 8]
processing item -> 9
processing item -> 10
items -> [9, 10]
...
```

From the above output, we can see two partitions are running concurrently, and each partition has a chunk size of 3, so the items are processed in this chunk size.   



